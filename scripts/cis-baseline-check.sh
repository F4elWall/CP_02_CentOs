#!/bin/bash

set -euo pipefail

LOG="/var/log/cis-baseline-check.log"
RELATORIO_HTML="/var/log/cis-baseline-check.html"
PASSOU=0
FALHOU=0
AVISO=0
PORCENTAGEM=0
CONCEITO="D"
TMPFILE=""

criar_log(){
        local nivel="$1"
        local mensagem="$2"
        local data
        data=$(date "+%Y-%m-%d %H:%M:%S")
        echo "[$data] [$nivel] $mensagem" | tee -a "$LOG"
}

usuario_root(){
        if [ "$EUID" -ne 0 ]; then
                criar_log "ERRO" "Rode o script como root"
                exit 3
        fi
}

verificar_deps(){
        for dep in sestatus ss find awk grep sshd systemctl sysctl stat rpm yum; do
                if ! command -v "$dep" &>/dev/null; then
                        criar_log "ERRO" "Dependência não encontrada: $dep"
                        exit 3
                fi
        done
        criar_log "INFO" "Todas as dependências encontradas."
}

uso_help(){
        echo "Uso: $0 [-h|--help]"
        echo ""
        echo "Script verificador de baseline CIS para CentOS Stream."
        echo "Deve ser executado como root."
        echo ""
        echo "Opções:"
        echo "  -h, --help    Mostra esta ajuda e sai"
        echo ""
        echo "Saídas:"
        echo "  Log:      $LOG"
        echo "  HTML:     $RELATORIO_HTML"
        echo ""
        echo "Códigos de saída:"
        echo "  0 — todas as verificações passaram"
        echo "  1 — uma ou mais verificações falharam"
        echo "  2 — erro de uso"
        echo "  3 — dependência ausente ou erro interno"
}

case "${1:-}" in
        -h|--help)
                uso_help
                exit 0
                ;;
        "")
                ;;
        *)
                echo "Opção inválida: $1" >&2
                uso_help
                exit 2
                ;;
esac

usuario_root
verificar_deps

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

criar_log "INFO" "Iniciando verificação de baseline CIS em $(hostname)..."

ver_selinux(){
        if sestatus 2>/dev/null | grep -q "Current mode:.*enforcing"; then
                criar_log "INFO" "SELinux em modo Enforcing"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "SELinux não está em modo Enforcing ou está desativado"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_selinux_politica(){
        local politica
        politica=$(sestatus 2>/dev/null | grep "Loaded policy name" | awk '{print $NF}')
        if [ "$politica" = "targeted" ]; then
                criar_log "INFO" "Política SELinux carregada: $politica"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Política SELinux não é 'targeted': $politica"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_tmp_nodev(){
        if findmnt -n -o OPTIONS /tmp 2>/dev/null | grep -q "nodev"; then
                criar_log "INFO" "/tmp montado com nodev"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/tmp não está montado com nodev"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_tmp_noexec(){
        if findmnt -n -o OPTIONS /tmp 2>/dev/null | grep -q "noexec"; then
                criar_log "INFO" "/tmp montado com noexec"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/tmp não está montado com noexec"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_tmp_nosuid(){
        if findmnt -n -o OPTIONS /tmp 2>/dev/null | grep -q "nosuid"; then
                criar_log "INFO" "/tmp montado com nosuid"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/tmp não está montado com nosuid"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_shm_nodev(){
        if findmnt -n -o OPTIONS /dev/shm 2>/dev/null | grep -q "nodev"; then
                criar_log "INFO" "/dev/shm montado com nodev"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/dev/shm não está montado com nodev"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_home_nosuid(){
        if findmnt -n -o OPTIONS /home 2>/dev/null | grep -q "nosuid"; then
                criar_log "INFO" "/home montado com nosuid"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/home não está montado com nosuid"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_var_separado(){
        if findmnt /var &>/dev/null; then
                criar_log "INFO" "/var está em partição separada"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/var não está em partição separada"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_varlog_noexec(){
        if findmnt -n -o OPTIONS /var/log 2>/dev/null | grep -q "noexec"; then
                criar_log "INFO" "/var/log montado com noexec"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "/var/log não está montado com noexec"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_avahi(){
        if systemctl is-enabled avahi-daemon &>/dev/null; then
                criar_log "ERRO" "Serviço avahi-daemon está habilitado — desative se não usar mDNS"
                FALHOU=$((FALHOU + 1))
        else
                criar_log "INFO" "Serviço avahi-daemon não está habilitado"
                PASSOU=$((PASSOU + 1))
        fi
}

ver_cups(){
        if systemctl is-enabled cups &>/dev/null; then
                criar_log "ERRO" "Serviço cups está habilitado — desative se não usar impressão"
                FALHOU=$((FALHOU + 1))
        else
                criar_log "INFO" "Serviço cups não está habilitado"
                PASSOU=$((PASSOU + 1))
        fi
}

ver_nfs(){
        if systemctl is-enabled nfs-server &>/dev/null; then
                criar_log "ERRO" "Serviço nfs-server está habilitado — desative se não usar compartilhamento"
                FALHOU=$((FALHOU + 1))
        else
                criar_log "INFO" "Serviço nfs-server não está habilitado"
                PASSOU=$((PASSOU + 1))
        fi
}

ver_rsyncd(){
        if systemctl is-enabled rsyncd &>/dev/null; then
                criar_log "ERRO" "Serviço rsyncd está habilitado"
                FALHOU=$((FALHOU + 1))
        else
                criar_log "INFO" "Serviço rsyncd não está habilitado"
                PASSOU=$((PASSOU + 1))
        fi
}

ver_telnet(){
        if rpm -q telnet-server &>/dev/null; then
                criar_log "ERRO" "Pacote telnet-server está instalado — prefira SSH"
                FALHOU=$((FALHOU + 1))
        else
                criar_log "INFO" "Pacote telnet-server não está instalado"
                PASSOU=$((PASSOU + 1))
        fi
}

ver_shadow(){
        local perm
        perm=$(stat -c "%a" /etc/shadow 2>/dev/null)
        if [ "$perm" = "0" ] || [ "$perm" = "000" ] || [ "$perm" = "640" ]; then
                criar_log "INFO" "Permissões de /etc/shadow corretas: $perm"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Permissões de /etc/shadow incorretas: $perm (esperado: 000 ou 640)"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_passwd(){
        local perm
        perm=$(stat -c "%a" /etc/passwd 2>/dev/null)
        if [ "$perm" = "644" ]; then
                criar_log "INFO" "Permissões de /etc/passwd corretas: $perm"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Permissões de /etc/passwd incorretas: $perm (esperado: 644)"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_group(){
        local perm
        perm=$(stat -c "%a" /etc/group 2>/dev/null)
        if [ "$perm" = "644" ]; then
                criar_log "INFO" "Permissões de /etc/group corretas: $perm"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Permissões de /etc/group incorretas: $perm (esperado: 644)"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_gshadow(){
        local perm
        perm=$(stat -c "%a" /etc/gshadow 2>/dev/null)
        if [ "$perm" = "0" ] || [ "$perm" = "000" ] || [ "$perm" = "640" ]; then
                criar_log "INFO" "Permissões de /etc/gshadow corretas: $perm"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Permissões de /etc/gshadow incorretas: $perm (esperado: 000 ou 640)"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_suid(){
        local conhecidos suspeitos arquivo
        conhecidos="
/usr/bin/su
/usr/bin/sudo
/usr/bin/passwd
/usr/bin/chsh
/usr/bin/chage
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/mount
/usr/bin/umount
/usr/sbin/unix_chkpwd
/usr/libexec/openssh/ssh-keysign
/usr/bin/at
/usr/bin/crontab
/usr/bin/pkexec
/usr/bin/chfn
/usr/lib/polkit-1/polkit-agent-helper-1
/usr/sbin/grub2-set-bootflag
/usr/sbin/pam_timestamp_check
"
        find / -xdev -perm /4000 -type f 2>/dev/null | sort > "$TMPFILE"
        suspeitos=""
        while IFS= read -r arquivo; do
                if ! echo "$conhecidos" | grep -qx "$arquivo"; then
                        suspeitos="$suspeitos $arquivo"
                fi
        done < "$TMPFILE"

        if [ -z "$suspeitos" ]; then
                criar_log "INFO" "Nenhum SUID suspeito encontrado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "AVISO" "SUID suspeitos encontrados:$suspeitos"
                AVISO=$((AVISO + 1))
        fi
}

ver_sgid(){
        local qtde
        qtde=$(find / -xdev -perm /2000 -type f 2>/dev/null | wc -l)
        if [ "$qtde" -le 20 ]; then
                criar_log "INFO" "Quantidade de arquivos SGID aceitável: $qtde"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "AVISO" "Muitos arquivos com SGID: $qtde — revise manualmente"
                AVISO=$((AVISO + 1))
        fi
}

ver_world_writable(){
        local qtde
        qtde=$(find / -xdev -type f -perm -0002 2>/dev/null | grep -vc "/proc" || true)
        if [ "$qtde" -eq 0 ]; then
                criar_log "INFO" "Nenhum arquivo world-writable encontrado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "$qtde arquivo(s) world-writable encontrado(s)"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_auditd_instalado(){
        if rpm -q audit &>/dev/null; then
                criar_log "INFO" "auditd instalado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "auditd não está instalado"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_auditd_rodando(){
        if systemctl is-active auditd &>/dev/null; then
                criar_log "INFO" "auditd em execução"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "auditd não está em execução"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_auditd_boot(){
        if systemctl is-enabled auditd &>/dev/null; then
                criar_log "INFO" "auditd habilitado no boot"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "auditd não está habilitado no boot"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_updates(){
        local qtde
        qtde=$(yum check-update --quiet 2>/dev/null | grep -c "^[a-zA-Z]" || true)
        if [ "${qtde:-0}" -eq 0 ]; then
                criar_log "INFO" "Nenhuma atualização pendente"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "AVISO" "$qtde pacote(s) com atualização disponível"
                AVISO=$((AVISO + 1))
        fi
}

ver_updates_seguranca(){
        local sec
        sec=$(yum check-update --security --quiet 2>/dev/null | grep -c "^[a-zA-Z]" || true)
        if [ "${sec:-0}" -eq 0 ]; then
                criar_log "INFO" "Nenhuma atualização de segurança pendente"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "$sec atualização(ões) de segurança pendentes"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_ssh_root(){
        local valor
        valor=$(sshd -T 2>/dev/null | grep "^permitrootlogin" | awk '{print $2}')
        if [ "$valor" = "no" ]; then
                criar_log "INFO" "Login root via SSH desabilitado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Login root via SSH está habilitado"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_ssh_maxauth(){
        local valor
        valor=$(sshd -T 2>/dev/null | grep "^maxauthtries" | awk '{print $2}')
        if [ -n "$valor" ] && [ "$valor" -le 4 ]; then
                criar_log "INFO" "MaxAuthTries configurado para $valor"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "MaxAuthTries não configurado ou maior que 4"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_firewall(){
        if systemctl is-active firewalld &>/dev/null || systemctl is-active iptables &>/dev/null; then
                criar_log "INFO" "Firewall ativo"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Nenhum firewall ativo"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_ip_forward(){
        local valor
        valor=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
        if [ "$valor" = "0" ]; then
                criar_log "INFO" "IP forwarding desabilitado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "IP forwarding está habilitado"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_aslr(){
        local valor
        valor=$(sysctl -n kernel.randomize_va_space 2>/dev/null)
        if [ "$valor" = "2" ]; then
                criar_log "INFO" "ASLR habilitado em nível 2"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "ASLR com valor $valor — esperado 2"
                FALHOU=$((FALHOU + 1))
        fi
}

ver_icmp_redirects(){
        local valor
        valor=$(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null)
        if [ "$valor" = "0" ]; then
                criar_log "INFO" "Envio de ICMP redirects desabilitado"
                PASSOU=$((PASSOU + 1))
        else
                criar_log "ERRO" "Envio de ICMP redirects habilitado"
                FALHOU=$((FALHOU + 1))
        fi
}

calcular_nota(){
        local total
        total=$((PASSOU + FALHOU + AVISO))
        if [ "$total" -eq 0 ]; then
                criar_log "ERRO" "Nenhum teste realizado"
                exit 3
        fi
        PORCENTAGEM=$((PASSOU * 100 / total))
        if [ "$PORCENTAGEM" -ge 90 ]; then
                CONCEITO="A"
        elif [ "$PORCENTAGEM" -ge 75 ]; then
                CONCEITO="B"
        elif [ "$PORCENTAGEM" -ge 60 ]; then
                CONCEITO="C"
        else
                CONCEITO="D"
        fi
        criar_log "INFO" "===== RESULTADO FINAL ====="
        criar_log "INFO" "Total de verificações : $total"
        criar_log "INFO" "Passaram              : $PASSOU"
        criar_log "INFO" "Falharam              : $FALHOU"
        criar_log "INFO" "Avisos                : $AVISO"
        criar_log "INFO" "Score                 : $PORCENTAGEM% — Conceito $CONCEITO"
}

gerar_html(){
        {
                echo "<!DOCTYPE html>"
                echo "<html lang='pt-BR'>"
                echo "<head><meta charset='UTF-8'>"
                echo "<title>Relatório CIS Baseline - $(hostname)</title>"
                echo "<style>"
                echo "body { font-family: monospace; background: #1e1e1e; color: #ccc; padding: 20px; }"
                echo "h1 { color: #fff; }"
                echo ".INFO  { color: #2ecc71; }"
                echo ".ERRO  { color: #e74c3c; }"
                echo ".AVISO { color: #f39c12; }"
                echo ".score { font-size: 1.4em; color: #fff; margin-top: 20px; }"
                echo "</style></head><body>"
                echo "<h1>Relatório CIS Baseline — $(hostname) — $(date)</h1>"
                echo "<pre>"
                while IFS= read -r linha; do
                        nivel=""
                        for n in INFO ERRO AVISO; do
                                if echo "$linha" | grep -q "\[$n\]"; then
                                        nivel="$n"
                                        break
                                fi
                        done
                        if [ -n "$nivel" ]; then
                                echo "<span class='$nivel'>$linha</span>"
                        else
                                echo "$linha"
                        fi
                done < "$LOG"
                echo "</pre>"
                echo "<p class='score'>Score final: $PORCENTAGEM% — Conceito $CONCEITO</p>"
                echo "</body></html>"
        } > "$RELATORIO_HTML"
        criar_log "INFO" "Relatório HTML salvo em: $RELATORIO_HTML"
}

criar_log "INFO" "=== SELinux ==="
ver_selinux
ver_selinux_politica

criar_log "INFO" "=== Montagens ==="
ver_tmp_nodev
ver_tmp_noexec
ver_tmp_nosuid
ver_shm_nodev
ver_home_nosuid
ver_var_separado
ver_varlog_noexec

criar_log "INFO" "=== Serviços desnecessários ==="
ver_avahi
ver_cups
ver_nfs
ver_rsyncd
ver_telnet

criar_log "INFO" "=== Permissões de arquivos ==="
ver_shadow
ver_passwd
ver_group
ver_gshadow

criar_log "INFO" "=== SUID / SGID / World-writable ==="
ver_suid
ver_sgid
ver_world_writable

criar_log "INFO" "=== auditd ==="
ver_auditd_instalado
ver_auditd_rodando
ver_auditd_boot

criar_log "INFO" "=== Atualizações ==="
ver_updates
ver_updates_seguranca

criar_log "INFO" "=== SSH ==="
ver_ssh_root
ver_ssh_maxauth

criar_log "INFO" "=== Firewall ==="
ver_firewall

criar_log "INFO" "=== Kernel / sysctl ==="
ver_ip_forward
ver_aslr
ver_icmp_redirects

calcular_nota
gerar_html

if [ "$FALHOU" -gt 0 ]; then
        exit 1
fi
exit 0
