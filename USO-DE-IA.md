# Uso por: Bernardo

# Objetivo
Desenvolver respostas para perguntas referentes ao CentOS

## Prompt 1: 

Quero que agora faça alternativas para as perguntas que eu te enviei, juntamente dos temas. As respostas da primeira pergunta devem ter mais de uma opção correta, e todas as de múltipla escolha devem ir de alternativa a) a e). Não use respostas muito absurdas, e exceto na primeira, não deve ter mais de uma resposta correta ou meio correta. Quanto às dissertativas, devem ser modelos de resposta esperadas, mas não rígidos. 

1. Múltipla escolha CentOS Stream — modelo upstream contínuo ou diferença para RHEL (faz 5 alternativas)  
2. Múltipla escolha LUKS — por que o /boot fica fora ou o conceito de risco residual (faz 5 alternativas)  
3. Múltipla escolha LVM — o que permite fazer a quente que o particionamento comum não permite (faz 5 alternativas)  
4. Dissertativa: Por que manter espaço livre no VG é requisito de segurança, não otimização?  
5. Dissertativa: Qual é o risco de manter o SSH na porta 22 com autenticação por senha?

## Prompt 2:

Me envie em formato de texto na conversa, ao invés de .docx
---

## Resultado

### 1. Múltipla escolha  
**CentOS Stream: modelo upstream contínuo ou diferença para o RHEL**  
*(mais de uma alternativa correta)*

a) É idêntico ao RHEL, uma cópia binária 1:1 apenas com nome diferente  

b) Fica posicionado como upstream contínuo, antes do RHEL na cadeia de desenvolvimento **(correta)**  

c) Serve como espaço de testes onde os pacotes são validados antes de entrarem na próxima versão point release do RHEL **(correta)**  

d) É um rolling release totalmente desconectado do ciclo de vida do RHEL  

e) Substitui completamente o RHEL em ambientes de produção crítica  

---

### 2. Múltipla escolha  
**LUKS: por que o /boot fica fora, ou o conceito de risco residual**

a) Porque o /boot não contém dado sensível e não precisa de proteção  

b) Porque o bootloader precisa ler o kernel e o initramfs antes que qualquer senha de descriptografia possa ser pedida — e o suporte do GRUB2 a /boot criptografado é limitado/complexo **(correta)**  

c) Porque o LUKS não é compatível com ext4  

d) Porque criptografar o /boot deixaria o boot mais rápido  

e) Porque o /boot sempre fica em um servidor remoto  

---

### 3. Múltipla escolha  
**LVM: o que permite fazer a quente**

a) Redimensionar (aumentar) um volume lógico e o sistema de arquivos sobre ele, sem precisar desmontar **(correta)**  

b) Instalar um sistema operacional sem bootloader  

c) Eliminar completamente a necessidade de backups  

d) Criptografar automaticamente todos os discos do sistema  

e) Rodar vários sistemas operacionais ao mesmo tempo na mesma partição  

---

### 4. Dissertativa  
**Por que manter espaço livre no VG é requisito de segurança, não otimização?**

Porque incidentes de segurança geram necessidade urgente de espaço, algo que não dá para prever com antecedência. Logs de auditoria podem crescer de forma explosiva durante um ataque e, se o disco enche, o sistema para de logar e você perde a evidência bem na hora em que mais precisa dela. Além disso, tirar um snapshot LVM para análise forense ou rollback também exige espaço livre no VG: sem ele, não dá para congelar o estado do sistema comprometido antes de mexer nele.

---

### 5. Dissertativa  
**Qual é o risco de manter o SSH na porta 22 com autenticação por senha?**

O maior risco está na autenticação por senha: ela é vulnerável a brute-force, dictionary attacks, credential stuffing e phishing, e não permite aplicar MFA de forma nativa e forte. Isso já seria um problema em qualquer porta, mas manter o serviço na porta padrão piora o cenário, porque é o primeiro alvo de scanners e botnets varrendo a internet o tempo todo. Trocar a porta não é uma proteção real, apenas reduz o ruído de ataques automatizados.

============================================================================================

# Uso por: Rafael

# Objetivo

Corrigir erro durante criação do Script

## Prompt: 

"Olá. Estou desenvolvendo um script e percebi um erro nele. Quero entender e saber como corrigir.
O set -euo pipefail está sendo habilitado, e a função:
uso_help(){
        echo "Script verificador de baseline CIS"
        echo "Uso excusivo para usuários root, por questões de segurança"
        echo "Uso para verificar configurações do sistema, inspirado no CIS."
        echo " -h, --help Mostra esta ajuda"
}
case "$1" in
        -h|--help)
                uso_help
                ;;
        *)
                ;;
esac
é chamada como verificação do argumento. Porem, a saída:
fael@BOOK-JMIOCV22RU:~/Testes$ ./script.sh
./script.sh: line 38: $1: unbound variable
fael@BOOK-JMIOCV22RU:~/Testes$"

## Resultado:

O erro acontece por causa do set -u (nounset).
Quando você executa o script sem nenhum argumento (./script.sh), a variável posicional $1 não existe. Com set -u ativado, qualquer referência a uma variável não definida gera exatamente este erro:
Bash./script.sh: line 38: $1: unbound variable
Como corrigir
A forma mais limpa e idiomática é usar a expansão com valor padrão vazio:
Bashcase "${1:-}" in
    -h|--help)
        uso_help
        ;;
    *)
        ;;
esac


# Uso por: Gustavo Gomes


## Prompt:

"Depois de criar os 7 pontos de montagem dentro do LVM, o instalador mostrou 12 GiB de espaço livre não alocado no grupo de volumes. Esse valor está dentro do esperado, considerando que o diagrama de referência usa números arredondados em GB?"

## Resposta:

Sim, está dentro do esperado. A diferença vem da unidade: o esquema de referência do trabalho usa números arredondados em GB, enquanto o instalador (Anaconda) trabalha em GiB. São unidades distintas — 1 GiB equivale a aproximadamente 1,073 GB — então a soma dos volumes nunca bate exatamente com a conta feita em GB, e sempre sobra um pouco mais ou menos do que o número "redondo" sugere.

O que realmente importa validar nesse ponto são três coisas: (1) os 7 pontos de montagem foram criados com os tamanhos previstos no diagrama; (2) sobrou espaço livre não alocado no Volume Group — o que não é desperdício, mas requisito explícito do trabalho, já que sem espaço livre no VG não é possível criar snapshots nem socorrer um volume que encheu; e (3) o disco não foi preenchido a 100%, situação que o próprio material do trabalho classifica como problema de planejamento, não otimização.

## Prompt:

"quando clico em Pronto no particionamento manual, o instalador retornou o erro Failed to find a suitable stage1 device: Partição de sistema EFI não pode ser do tipo lvmpv. oq esse erro significa?"

## Resposta:

Não é normal, mas é um erro comum de configuração e tem correção simples. A mensagem indica que o instalador tentou colocar a partição /boot/efi dentro do LVM, o que não é permitido: a partição de sistema EFI precisa ficar fora do LVM e fora da criptografia, porque o firmware UEFI precisa conseguir lê-la antes de o sistema operacional existir — ou seja, antes de haver qualquer possibilidade de solicitar a passphrase do LUKS.

Isso costuma acontecer quando os pontos de montagem são criados manualmente um a um com o esquema LVM selecionado: o instalador tenta encaixar automaticamente a /boot/efi no mesmo esquema dos demais volumes.

A correção consiste em criar /boot/efi (1 GiB) e /boot (1 GiB) explicitamente, alterando no painel de detalhes o campo "Tipo de dispositivo" de LVM para Partição Padrão, e mantendo a caixa "Criptografar" desmarcada nessas duas — mesmo com a opção global de criptografia ativa. Os demais 7 pontos de montagem permanecem como LVM e criptografados.

## USO POR: Rafael

##Instruções de como aplicar a lógica das análises e exemplos base

#Prompts:
Como descubro o status do SELinux num script shell?

Resposta:
Use o sestatus 2>/dev/null. O 2>/dev/null evita erros, caso não seja instalado. 

#Prompt:
E como sabber se está no modo enforcing?

Resposta:

#Você pode usar o grep -q "Current mode: .*enforcing". Use -q para mostrar apenas true ou false

#Prompt:
Como usar o comando findmnt para verificar as partições?

Resposta:

Utilize as opções -n -o OPTIONS<partição>. -n = remove cabeçalho e -o OPTIONS retorna as opções de montagem para verificar. Pode usar o | grep -q "<opção> para filtrar

#Prompt
Preciso verificar o status das permissões de alguns arquivos

Resposta:
Use stat -c "%a" <arquivo>. Isso retorna as permissões em formato octal. 

#Prompt:
Como listo todos os arquivos SUID do sistema num script shell?

Resposta: Use find com -perm /4000:

find / -xdev -perm /4000 -type f 2>/dev/null | sort

O -xdev evita cruzar outros sistemas de arquivos, e 2>/dev/null suprime erros de permissão.
 

 
#Prompt: 
Como comparo essa lista com uma whitelist de SUIDs conhecidos?

Resposta: 

Leia o resultado linha por linha e use `grep -qx` para checar correspondência exata com a lista:

if ! echo "$conhecidos" | grep -qx "$arquivo"; then
    suspeitos="$suspeitos $arquivo"
fi
O -x exige que a linha inteira bata, evitando falsos positivos.
 
#Prompt: 
Como leio um arquivo linha por linha sem quebrar em espaços?

Resposta:

Use while IFS= read -r:

while IFS= read -r arquivo; do
done < "$TMPFILE"
 
O IFS= evita que espaços quebrem a linha, e -r impede interpretação de barras invertidas.
