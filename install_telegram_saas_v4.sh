#!/bin/bash

# =============================================================================
# SCRIPT DE INSTALAÇÃO AUTOMATIZADA - TELEGRAM SAAS MULTI-CONTA v4.0
# =============================================================================
# Autor: Desenvolvido para replicação rápida em VPS Ubuntu 22.04
# Versão: 4.0 (Sistema completo com webhooks individuais e agendamento)
# Data: 13/08/2025
# =============================================================================

set -e  # Parar execução em caso de erro

# Configurar ambiente não-interativo
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se é Ubuntu 22.04
check_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "22.04" ]]; then
            return 0
        fi
    fi
    return 1
}

# Banner de início
echo -e "${BLUE}"
echo "============================================================================="
echo "    INSTALADOR AUTOMÁTICO - TELEGRAM SAAS MULTI-CONTA v4.0"
echo "    (Sistema completo com webhooks individuais e agendamento)"
echo "============================================================================="
echo -e "${NC}"

# Verificar se é root ou tem sudo
if [[ $EUID -ne 0 ]] && ! command_exists sudo; then
    log_error "Este script precisa ser executado como root ou com sudo disponível"
    exit 1
fi

# Verificar versão do Ubuntu
if ! check_ubuntu_version; then
    log_warning "Este script foi testado apenas no Ubuntu 22.04"
    log_info "Continuando mesmo assim..."
fi

# Definir diretório de instalação
INSTALL_DIR="/root/telegram-saas"

log_info "Iniciando instalação da plataforma Telegram SaaS v4.0..."

# 1. Configurar repositórios e atualizar sistema
log_info "Configurando ambiente não-interativo e atualizando sistema..."

# Configurar debconf para não fazer perguntas
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Atualizar sistema sem interações
if command_exists sudo; then
    sudo -E apt-get update -qq
    sudo -E apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    sudo -E apt-get install -y -qq python3 python3-pip python3-venv wget unzip curl
else
    apt-get update -qq
    apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    apt-get install -y -qq python3 python3-pip python3-venv wget unzip curl
fi

log_success "Sistema atualizado e dependências instaladas"

# 2. Criar diretório e preparar ambiente
log_info "Preparando ambiente de instalação..."

# Remover diretório existente se houver
if [[ -d "$INSTALL_DIR" ]]; then
    log_warning "Diretório $INSTALL_DIR já existe. Fazendo backup..."
    mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Criar diretório final
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/static"

log_success "Diretório de instalação preparado"

# 3. Criar ambiente virtual do zero
log_info "Criando ambiente virtual Python do zero..."
cd "$INSTALL_DIR"

# Criar novo ambiente virtual
python3 -m venv venv

# Ativar ambiente virtual e instalar dependências
source venv/bin/activate
pip install --upgrade pip
pip install flask==3.0.0 flask-cors==4.0.0 telethon==1.40.0 requests==2.31.0 schedule==1.2.0

# Verificar se as dependências foram instaladas corretamente
if ! python -c "import telethon, flask, requests, schedule" 2>/dev/null; then
    log_error "Falha ao instalar dependências Python"
    exit 1
fi

deactivate

log_success "Ambiente virtual criado e dependências instaladas"

# 4. Criar arquivos do sistema
log_info "Criando arquivos do sistema..."

# Criar arquivo config.json padrão
cat > config.json << 'EOF'
{
  "webhook_url": "",
  "accounts_webhooks": {}
}
EOF

# Criar arquivo requirements.txt
cat > requirements.txt << 'EOF'
flask==3.0.0
flask-cors==4.0.0
telethon==1.40.0
requests==2.31.0
schedule==1.2.0
EOF

log_success "Arquivos de configuração criados"

# 5. Verificar se o ambiente está funcionando
log_info "Testando ambiente Python..."
if "$INSTALL_DIR/venv/bin/python" -c "import telethon, flask, requests, schedule; print('✅ Todas as dependências OK')" 2>/dev/null; then
    log_success "Ambiente Python verificado e funcionando"
else
    log_error "Problema com o ambiente Python"
    exit 1
fi

# 6. Criar arquivos de serviço systemd
log_info "Configurando serviços systemd..."

# Parar serviço se já estiver rodando
systemctl stop telegram-api 2>/dev/null || true

# Serviço da API
cat > /etc/systemd/system/telegram-api.service << EOF
[Unit]
Description=Telegram API Server v4.0
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python telegram_api_v4.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=telegram-api
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

log_success "Serviços systemd configurados"

# 7. Recarregar systemd e habilitar serviços
log_info "Habilitando serviços..."
systemctl daemon-reload
systemctl enable telegram-api

# 8. Obter IP da VPS
log_info "Obtendo IP da VPS..."
VPS_IP=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}' || echo "SEU_IP_VPS")

# 9. Configurar firewall se ufw estiver ativo
if command_exists ufw && ufw status | grep -q "Status: active"; then
    log_info "Configurando firewall para porta 5000..."
    ufw allow 5000/tcp >/dev/null 2>&1 || true
    log_success "Firewall configurado"
fi

# 10. Criar script de gerenciamento
log_info "Criando script de gerenciamento..."
cat > /usr/local/bin/telegram-saas << 'EOF'
#!/bin/bash

case "$1" in
    start)
        systemctl start telegram-api
        echo "Serviço iniciado"
        ;;
    stop)
        systemctl stop telegram-api
        echo "Serviço parado"
        ;;
    restart)
        systemctl restart telegram-api
        echo "Serviço reiniciado"
        ;;
    status)
        systemctl status telegram-api --no-pager
        ;;
    logs)
        journalctl -u telegram-api -f
        ;;
    dashboard)
        VPS_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
        echo "Dashboard disponível em: http://$VPS_IP:5000"
        echo "Senha de acesso: Te1234"
        ;;
    test)
        echo "Testando API..."
        if curl -s --max-time 10 "http://localhost:5000/api/status" >/dev/null 2>&1; then
            echo "✅ API está funcionando"
        else
            echo "❌ API não está respondendo"
        fi
        ;;
    install-deps)
        echo "Reinstalando dependências Python..."
        cd /root/telegram-saas
        source venv/bin/activate
        pip install --upgrade flask flask-cors telethon requests schedule
        deactivate
        echo "Dependências reinstaladas"
        ;;
    *)
        echo "Uso: telegram-saas {start|stop|restart|status|logs|dashboard|test|install-deps}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/telegram-saas

log_success "Script de gerenciamento criado em /usr/local/bin/telegram-saas"

# 11. Limpeza
log_info "Limpando arquivos temporários..."
rm -f accounts.json
rm -f scheduled_messages.json
rm -f system_logs.json
rm -f session_*.session

# 12. Exibir informações finais
echo
echo -e "${GREEN}============================================================================="
echo "    INSTALAÇÃO v4.0 CONCLUÍDA COM SUCESSO!"
echo "=============================================================================${NC}"
echo
echo -e "${BLUE}📋 INFORMAÇÕES DA INSTALAÇÃO:${NC}"
echo "   • Diretório: $INSTALL_DIR"
echo "   • Serviço: telegram-api.service"
echo "   • Dashboard: http://$VPS_IP:5000"
echo "   • Senha de acesso: Te1234"
echo "   • Ambiente Virtual: Criado do zero nesta máquina"
echo
echo -e "${BLUE}🚀 COMANDOS ÚTEIS:${NC}"
echo "   • telegram-saas start        - Iniciar serviço"
echo "   • telegram-saas stop         - Parar serviço"
echo "   • telegram-saas restart      - Reiniciar serviço"
echo "   • telegram-saas status       - Ver status"
echo "   • telegram-saas logs         - Ver logs em tempo real"
echo "   • telegram-saas dashboard    - Mostrar URL do dashboard"
echo "   • telegram-saas test         - Testar se API está funcionando"
echo "   • telegram-saas install-deps - Reinstalar dependências Python"
echo
echo -e "${BLUE}🆕 NOVIDADES v4.0:${NC}"
echo "   • ✅ Sistema de login com senha Te1234"
echo "   • ✅ Webhooks individuais por conta"
echo "   • ✅ Agendamento de mensagens"
echo "   • ✅ Criação e gerenciamento de grupos"
echo "   • ✅ Adição de leads em massa"
echo "   • ✅ Sistema de logs avançado"
echo "   • ✅ API completa com 16 endpoints"
echo "   • ✅ Interface moderna e responsiva"
echo
echo -e "${BLUE}📱 PRÓXIMOS PASSOS:${NC}"
echo "   1. Inicie o serviço: telegram-saas start"
echo "   2. Acesse o dashboard: http://$VPS_IP:5000"
echo "   3. Faça login com a senha: Te1234"
echo "   4. Conecte suas contas Telegram"
echo "   5. Configure webhooks individuais"
echo "   6. Comece a usar todas as funcionalidades!"
echo
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "   • Certifique-se de que a porta 5000 está aberta no firewall"
echo "   • Use 'telegram-saas logs' para monitorar problemas"
echo "   • Use 'telegram-saas test' para verificar se a API está funcionando"
echo "   • Documentação completa disponível na aba 'API Docs'"
echo
echo -e "${GREEN}✅ Sistema Telegram SaaS v4.0 pronto para uso!${NC}"

echo
log_info "Para iniciar o sistema agora, execute: telegram-saas start"
echo

