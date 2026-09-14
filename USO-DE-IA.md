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
