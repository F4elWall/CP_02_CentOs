INSTALL.md — Instalação Segura de CentOS Stream com LVM sobre LUKS e SSH Endurecido
Grupo: 6 — CentOS Stream Disciplina: Sistemas Operacionais Linux — Cibersegurança Objetivo: documentar, de forma reproduzível, a instalação segura da distribuição, o esquema de particionamento com LVM sobre LUKS, e o endurecimento do serviço SSH.
---
1. Pré-requisitos
Item	Especificação
Hipervisor	VirtualBox
Firmware	UEFI habilitado
Disco principal	60 GB
Disco secundário	20 GB (adicionado depois da instalação)
Memória / vCPU	4 GB / 2 vCPU
Rede	NAT (nunca Bridge exposto)
Tipo de instalação	Server sem GUI / Minimal Install
SELinux	Enforcing do início ao fim
1.1 Download e verificação da ISO
# Baixe a ISO oficial do CentOS Stream em https://www.centos.org/download/
# Depois, verifique a integridade com o hash SHA-256 divulgado no site oficial:
sha256sum CentOS-Stream-9-latest-x86_64-dvd1.iso
# Compare a saída com o hash publicado — não prossiga se forem diferentes
---
2. Criação da máquina virtual
Novo hipervisor → Tipo: Linux → Versão: Red Hat (64-bit)
Memória: 4096 MB
Processadores: 2 vCPU
Firmware: UEFI (não BIOS)
Disco principal: 60 GB, alocação dinâmica
Rede: Adaptador 1 → NAT
Anexe a ISO baixada na unidade óptica
>   
> ![][image1]
Marque a caixinha escrito “UEFI”, como na imagem acima.
3. Esquema de particionamento (planejado antes da instalação)
Este é o diagrama de particionamento, verifique antes de qualquer instalação:
sda1  /boot/efi   1 GB   FAT32              (fora da criptografia)
sda2  /boot       1 GB   xfs                (fora da criptografia)
sda3  ~58 GB      LUKS2  container criptografado
└── VG vg_sistema (PV = /dev/mapper/cryptlvm)
        lv\_root     15 G   /

        lv\_var       8 G   /var

        lv\_varlog    5 G   /var/log

        lv\_vartmp    3 G   /var/tmp

        lv\_home     10 G   /home

        lv\_tmp       3 G   /tmp

        lv\_swap      4 G   swap

        espaço livre \~9 G  (reservado para snapshots)

Por que essa estrutura:
`/boot` fica fora do LUKS porque o GRUB precisa ler o kernel antes de existir qualquer chave de descriptografia. Esse é o risco residual do esquema — a chave de boot não é protegida por criptografia, apenas o conteúdo do sistema.
Um único container LUKS2 hospeda o volume group inteiro: uma única passphrase é pedida no boot, e qualquer LV criado depois já nasce criptografado.
O espaço livre reservado no VG não é desperdício — é o que permite criar snapshots ou estender um volume que encher, sem precisar reparticionar.
>   

4. Instalação (Anaconda)

Na tela inicial, escolha Install CentOS Stream 10
Idioma: Português (Brasil) ou Inglês, conforme preferência do grupo
Installation Destination → selecione o disco de 60 GB → Custom (particionamento manual)
Anaconda entra no editor de particionamento manual:
Crie `/boot/efi` — 1 GiB — EFI System Partition
Crie `/boot` — 1 GiB — xfs
Crie o restante do disco (~58 GiB) como LUKS2 (marque a caixa "Encrypt")
Defina a passphrase do LUKS neste momento — anote em local seguro, fora da VM. Não existe recuperação sem ela.
Dentro do container criptografado, crie o Volume Group `vg_sistema`
Crie os Logical Volumes conforme a tabela do item 3, deixando ~9 GiB livres no VG
Confirme o resumo de particionamento e aceite a formatação
Software Selection → Minimal Install (sem ambiente gráfico)
Network & Host Name → configure o hostname da VM
Crie o usuário administrador (não use root para uso diário) e defina a senha do usuário local
Inicie a instalação
---
5. Primeiro boot e checklist pós-instalação
# Confirme a versão da distribuição
cat /etc/os-release
# Confirme o kernel
uname -r
# Confirme o SELinux
getenforce      # deve retornar: Enforcing
sestatus
> 
Snapshot obrigatório neste ponto: desligue a VM e crie um snapshot chamado `pos-instalacao-limpa` antes de qualquer configuração adicional.
---
6. Verificação de disco, LUKS e LVM
lsblk -f
sudo cryptsetup luksDump /dev/sda3
sudo pvs
sudo vgs
sudo lvs
sudo findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
cat /etc/fstab
cat /etc/crypttab
6.1 Opções de montagem restritivas
Editamos `/etc/fstab` para aplicar as seguintes opções, conforme a tabela de ameaças do enunciado:
Ponto de montagem	Opções aplicadas	O que bloqueia
`/tmp`, `/var/tmp`	`nodev,nosuid,noexec`	Execução de payload gravado em diretório mundialmente gravável
`/home`	`nodev,nosuid`	Usuário comum criar binário SUID no próprio diretório
`/var/log`	`nodev,nosuid,noexec`	Integridade dos logs e uso da área de log como staging
`/boot`, `/var`	`nodev` (+ `nosuid` no `/boot`)	Isolamento da área de boot e de dados de serviço
Confirmação: execução do findmnt mostrou rw,nosuid,nodev,noexec,relatime,... aplicado corretamente. O teste da execução do script resultou em -bash: ./t.sh: Permissão negada, com RESULTADO: 126.  
Decisão do grupo: manter as opções restritivas como definidas no esquema de referência. Nenhum ajuste ou reversão foi necessário — o comportamento observado era o esperado após a remontagem, confirmando que a proteção contra execução em /var/tmp está funcionando corretamente.
 -------
7. Ciclo de vida do LVM — adicionando o segundo disco
Com a VM desligada, adicione o disco secundário de 20 GB nas configurações do hipervisor. Depois, com a VM ligada:
# Identifique o novo disco (ex.: /dev/sdb)
sudo lsblk
# Crie o Physical Volume
sudo pvcreate /dev/sdb
# Estenda o Volume Group existente
sudo vgextend vg_sistema /dev/sdb
# Estenda o Logical Volume desejado (exemplo: lv_home, +10G)
sudo lvextend -L +10G /dev/vg_sistema/lv_home
# Redimensione o sistema de arquivos xfs a quente
sudo xfs_growfs /home

---

8. Endurecimento do serviço SSH
8.1 Geração do par de chaves (na máquina cliente/host)
ssh-keygen -t ed25519 -C "acesso-vm-centos"
# Copie a chave pública para a VM
ssh-copy-id -p 22 usuario@IP_DA_VM
8.2 Configuração do `/etc/ssh/sshd_config`
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowGroups ssh-users
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
Crie o grupo dedicado e adicione o usuário administrador a ele:
sudo groupadd ssh-users
sudo usermod -aG ssh-users usuario
8.3 Validação antes de recarregar (regra de ouro)
sudo sshd -t          # valida a sintaxe antes de qualquer reinício
sudo systemctl reload sshd
> **Nunca feche a sessão SSH atual antes de confirmar, em uma segunda sessão aberta em paralelo, que a nova configuração funciona.**
8.4 SELinux — ajuste do rótulo da porta customizada
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo semanage port -l | grep ssh
8.5 firewalld — liberar apenas a porta nova
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-rich-rule='rule service name="ssh" limit value="3/m" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
8.6 Políticas de criptografia
sudo update-crypto-policies --set DEFAULT
# Remover cifras/MACs legados via política customizada, se necessário
8.7 Banner de aviso legal
sudo tee /etc/issue.net <<'EOF'
Acesso restrito. Esta atividade pode ser monitorada e registrada.
Uso não autorizado é crime, conforme Art. 154-A do Código Penal.
EOF
Adicione `Banner /etc/issue.net` ao `sshd_config` e recarregue o serviço.
> ![][image5]  
> ![][image6]  
> ![][image7]  
---
9. Acesso remoto entre máquinas diferentes (NAT + Port Forwarding)
Como a VM usa rede NAT, o IP interno (`10.0.2.15`) só é visível de dentro da rede virtual. Para acesso de outra máquina física, foram configuradas duas camadas de redirecionamento:
Máquina remota → IP público do roteador:2222
              → Port Forwarding do roteador → 192.168.15.2:2222 (Windows host)

              → Port Forwarding do VirtualBox → 10.0.2.15:2222 (VM CentOS)

9.1 Port Forwarding no VirtualBox
Configurações da VM → Rede → Adaptador 1 → Avançado → Encaminhamento de Portas:
Nome	Protocolo	Porta do Hospedeiro	Porta do Convidado
SSH	TCP	2222	2222
9.2 Port Forwarding no roteador (para acesso externo à rede local)
Reserva de IP fixo para o host Windows (`192.168.15.2`), seguida de regra de redirecionamento no roteador: porta externa `2222` TCP → IP interno `192.168.15.2` → porta interna `2222`.
9.3 Regra de firewall no Windows (host)
Firewall do Windows Defender com Segurança Avançada → Regras de Entrada → Nova Regra → Porta → TCP `2222` → Permitir.
9.4 Comando de teste (da máquina remota)
ssh -i ~/.ssh/id_ed25519 -p 2222 usuario@IP_PUBLICO_DO_ROTEADOR
---
10. Evidências (comandos de conferência)
# Disco, LUKS e LVM
lsblk -f
sudo cryptsetup luksDump /dev/sda3
sudo pvs; sudo vgs; sudo lvs
sudo findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
cat /etc/fstab; cat /etc/crypttab
# Sistema e SELinux
cat /etc/os-release
uname -r
getenforce
sestatus
# SSH e firewall
sudo sshd -T
systemctl status sshd
sudo firewall-cmd --list-all
ss -tulpn
sudo semanage port -l | grep ssh
---
11. Troubleshooting
11.1 `ssh: connect to host 10.0.2.15 port 2222: Connection refused`
Causa: tentativa de conectar diretamente ao IP interno do NAT (`10.0.2.15`) a partir do host físico. Esse IP só existe dentro da rede virtual do VirtualBox; o host não tem rota até ele.
Solução: conectar via `127.0.0.1` (do próprio host onde a VM roda), usando a regra de Port Forwarding do VirtualBox:
ssh -i ~/.ssh/id_ed25519 -p 2222 usuario@127.0.0.1


11.2 Amigo/colega de outra máquina não consegue conectar
Causa: `127.0.0.1` só é válido na mesma máquina física onde o VirtualBox está rodando. Uma segunda camada de redirecionamento é necessária.
Solução: configurar Port Forwarding também no roteador de casa, apontando para o IP local do host Windows (ver seção 9). Testado com sucesso após:
Reserva de DHCP de IP `específico` no roteador
Regra de redirecionamento de porta `2222` TCP no roteador (Vivo Fibra, painel em `192.168.15.1`)
Regra de entrada liberando a porta `2222` no Firewall do Windows
11.3 `sshd -t` reporta erro de sintaxe após editar `sshd_config`
Causa comum: diretiva duplicada, incompatível ou digitada incorretamente.
Solução: sempre rodar `sudo sshd -t` antes de `systemctl reload sshd`. Se o teste falhar, o serviço antigo continua rodando na sessão atual — corrija o arquivo e teste novamente antes de recarregar.


11.4 `Permission denied (publickey)` ao conectar com chave
Causas possíveis e verificações:
ls -ld ~/.ssh              # deve ser 700
ls -l ~/.ssh/authorized_keys  # deve ser 600
sudo restorecon -Rv ~/.ssh    # corrige contexto SELinux, se necessário


---
12. Referências
Documentação oficial do CentOS Stream: https://docs.centos.org/
Red Hat Enterprise Linux Security Guide (aplicável ao CentOS Stream por herança upstream)
