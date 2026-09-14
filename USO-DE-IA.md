Objetivo: Desenvolver respostas para perguntas referentes a o CentOs


Prompt:1 
Múltipla escolha CentOS Stream — modelo upstream contínuo ou diferença para RHEL (faz 5 alternativas)
2 Múltipla escolha LUKS — por que o /boot fica fora ou o conceito de risco residual (faz 5 alternativas)
3 Múltipla escolha LVM — o que permite fazer a quente que o particionamento comum não permite(faz 5 alternativas)
4 Dissertativa Por que manter espaço livre no VG é requisito de segurança, não otimização?
5 Dissertativa Qual é o risco de manter o SSH na porta 22 com autenticação por senha?

faca essas perguntas e com as respostas
-----------------------
quero que me  envie elas por texto, e a primeira pergunta com mais de uma alternativa correta


Resultado:
1. Múltipla escolha 
CentOS Stream: modelo upstream contínuo ou diferença para o RHEL (mais de uma correta)
a) É idêntico ao RHEL, uma cópia binária 1:1 apenas com nome diferente
b)  Fica posicionado como upstream contínuo, antes do RHEL na cadeia de desenvolvimento (certa)
c)  Serve como espaço de testes onde os pacotes são validados antes de entrarem na próxima versão point release do RHEL (certa)
d) É um rolling release totalmente desconectado do ciclo de vida do RHEL
e) Substitui completamente o RHEL em ambientes de produção crítica
-----------------------------------------------------------------------------------------------------------------
2.  Múltipla escolha 
LUKS: por que o /boot fica fora, ou o conceito de risco residual
a) Porque o /boot não contém dado sensível e não precisa de proteção
b) Porque o bootloader precisa ler o kernel e o initramfs antes que qualquer senha de descriptografia possa ser pedida — e o suporte do GRUB2 a /boot criptografado é limitado/complexo (certa)
c) Porque o LUKS não é compatível com ext4
d) Porque criptografar o /boot deixaria o boot mais rápido
e) Porque o /boot sempre fica em um servidor remoto
----------------------------------------------------------------------------------------
 3. Múltipla escolha 
LVM: o que permite fazer a quente

a)  Redimensionar (aumentar) um volume lógico e o sistema de arquivos sobre ele, sem precisar desmontar✅
b) Instalar um sistema operacional sem bootloader
c) Eliminar completamente a necessidade de backups
d) Criptografar automaticamente todos os discos do sistema
e) Rodar vários sistemas operacionais ao mesmo tempo na mesma partição
-------------------------------------------------------------------------------------------------------------------------
4. Dissertativa 
Por que manter espaço livre no VG é requisito de segurança, não otimização?

Porque incidentes de segurança geram necessidade urgente de espaço, algo que não dá pra prever com antecedência. Logs de auditoria podem crescer de forma explosiva durante um ataque, e se o disco enche, o sistema para de logar e você perde a evidência bem na hora em que mais precisa dela. Além disso, tirar um snapshot LVM para análise forense ou rollback também exige espaço livre no VG sem ele, não dá pra congelar o estado do sistema comprometido antes de mexer nele.
-----------------------------------------------------------------------
 5. Qual é o risco de manter o SSH na porta 22 com autenticação por senha?

O maior risco está na autenticação por senha: ela é vulnerável a brute-force, dictionary attacks, credential stuffing e phishing, e não permite aplicar MFA de forma nativa e forte. Isso já seria um problema em qualquer porta, mas manter o serviço na porta padrão  piora o cenário, porque é o primeiro alvo de scanners e botnets varrendo a internet o tempo todo, trocar a porta não é uma proteção real, apenas reduz o ruído de ataques automatizados
