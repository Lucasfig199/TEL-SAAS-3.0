#!/bin/bash

# Telegram SaaS Pro v4 - Instalador GitHub
# Versão: 4.0 Final Corrigido
# Data: 10/08/2025

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
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

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
    echo "===================================="
}

# Configurações
GITHUB_USER="Lucasfig199"
GITHUB_REPO="TEL-SAAS-3.0"
ZIP_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/raw/main/telegram-saas-integrado-final.zip"
PROJECT_DIR="telegram-saas-integrado"

# Header
clear
log_header "Telegram SaaS Pro v4 - Instalador GitHub"

# 1. Atualizar sistema
log_info "1/9 Atualizando sistema..."
if command -v apt-get &> /dev/null; then
    apt-get update -y > /dev/null 2>&1 || log_warning "Falha na atualização do sistema"
elif command -v yum &> /dev/null; then
    yum update -y > /dev/null 2>&1 || log_warning "Falha na atualização do sistema"
fi
log_success "Sistema atualizado"

# 2. Instalar dependências do sistema
log_info "2/9 Instalando dependências do sistema..."
if command -v apt-get &> /dev/null; then
    apt-get install -y python3 python3-pip python3-venv curl wget unzip > /dev/null 2>&1 || {
        log_warning "Tentando instalação individual..."
        apt-get install -y python3 || true
        apt-get install -y python3-pip || true
        apt-get install -y python3-venv || true
        apt-get install -y curl || true
        apt-get install -y wget || true
        apt-get install -y unzip || true
    }
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip curl wget unzip > /dev/null 2>&1 || {
        log_warning "Tentando instalação individual..."
        yum install -y python3 || true
        yum install -y python3-pip || true
        yum install -y curl || true
        yum install -y wget || true
        yum install -y unzip || true
    }
fi
log_success "Dependências do sistema instaladas"

# 3. Verificar Python
log_info "3/9 Verificando Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    log_success "Python encontrado: $PYTHON_VERSION"
else
    log_error "Python3 não encontrado!"
    exit 1
fi

# 4. Baixar arquivos do GitHub
log_info "4/9 Baixando arquivos do GitHub..."
log_info "    Baixando de: $ZIP_URL"

# Remover diretório existente se houver
if [ -d "$PROJECT_DIR" ]; then
    log_warning "Diretório $PROJECT_DIR já existe, removendo..."
    rm -rf "$PROJECT_DIR"
fi

# Baixar ZIP com timeout e retry
for i in {1..3}; do
    if curl -L --connect-timeout 30 --max-time 300 -o telegram-saas-integrado.zip "$ZIP_URL"; then
        log_success "Arquivo baixado com sucesso"
        break
    else
        log_warning "Tentativa $i/3 falhou, tentando novamente..."
        if [ $i -eq 3 ]; then
            log_error "Falha ao baixar arquivo após 3 tentativas"
            exit 1
        fi
        sleep 5
    fi
done

# 5. Extrair arquivos
log_info "5/9 Extraindo arquivos..."
if [ -f "telegram-saas-integrado.zip" ]; then
    unzip -q telegram-saas-integrado.zip -d "$PROJECT_DIR" || {
        log_error "Falha ao extrair arquivo ZIP"
        exit 1
    }
    rm telegram-saas-integrado.zip
    log_success "Arquivos extraídos"
else
    log_error "Arquivo ZIP não encontrado"
    exit 1
fi

# 6. Entrar no diretório do projeto
cd "$PROJECT_DIR"

# 7. Verificar pip3
log_info "6/9 Verificando pip3..."
if command -v pip3 &> /dev/null; then
    log_success "pip3 encontrado"
else
    log_warning "pip3 não encontrado, tentando instalar..."
    if command -v apt-get &> /dev/null; then
        apt-get install -y python3-pip
    elif command -v yum &> /dev/null; then
        yum install -y python3-pip
    fi
fi

# 8. Criar ambiente virtual
log_info "7/9 Criando ambiente virtual..."
if [ ! -d "venv" ]; then
    python3 -m venv venv || {
        log_warning "Falha ao criar venv, tentando alternativa..."
        python3 -m pip install --user virtualenv
        python3 -m virtualenv venv
    }
fi
source venv/bin/activate
log_success "Ambiente virtual criado e ativado"

# 9. Instalar dependências Python
log_info "8/9 Instalando dependências Python..."
pip install --upgrade pip > /dev/null 2>&1 || log_warning "Falha ao atualizar pip"

# Instalar dependências do requirements.txt
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt > /dev/null 2>&1 || {
        log_warning "Falha com requirements.txt, instalando individualmente..."
        pip install flask telethon requests python-dotenv > /dev/null 2>&1
    }
else
    log_warning "requirements.txt não encontrado, instalando dependências básicas..."
    pip install flask telethon requests python-dotenv > /dev/null 2>&1
fi
log_success "Dependências Python instaladas"

# 10. Configurar sistema
log_info "9/9 Configurando sistema..."

# Verificar e criar arquivos JSON se necessário
for file in accounts.json webhooks.json config.json scheduled_messages.json; do
    if [ ! -f "$file" ]; then
        log_warning "Arquivo $file não encontrado, criando..."
        case $file in
            "accounts.json") echo '[]' > "$file" ;;
            "webhooks.json") echo '{}' > "$file" ;;
            "config.json") echo '{"webhook_url": ""}' > "$file" ;;
            "scheduled_messages.json") echo '[]' > "$file" ;;
        esac
    fi
done

# Verificar arquivo principal
if [ ! -f "telegram_api_v4.py" ]; then
    log_error "Arquivo telegram_api_v4.py não encontrado!"
    exit 1
fi

# Verificar diretório static
if [ ! -d "static" ]; then
    log_warning "Diretório static não encontrado, criando..."
    mkdir -p static
fi

if [ ! -f "static/index.html" ]; then
    log_error "Arquivo static/index.html não encontrado!"
    exit 1
fi

# Testar sintaxe do Python
python3 -m py_compile telegram_api_v4.py || {
    log_error "Erro na sintaxe do arquivo principal"
    exit 1
}

# Testar importações
python3 -c "
try:
    import flask, telethon, requests, json, os
    print('✅ Todas as bibliotecas importadas com sucesso')
except ImportError as e:
    print(f'❌ Erro de importação: {e}')
    exit(1)
" || {
    log_error "Erro na verificação das bibliotecas"
    exit 1
}

log_success "Sistema configurado"

# Finalização
echo ""
log_header "INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo ""
log_success "Telegram SaaS Pro v4 instalado e 100% funcional!"
echo ""
echo -e "${CYAN}📋 PRÓXIMOS PASSOS:${NC}"
echo "1. cd $PROJECT_DIR"
echo "2. ./run.sh"
echo "3. Acesse: http://localhost:5000"
echo "4. Conecte suas contas na aba 'Conectar Conta'"
echo "5. Configure webhooks na aba 'Gerenciar Contas'"
echo ""
echo -e "${CYAN}🔧 COMANDOS ÚTEIS:${NC}"
echo "• Iniciar: ./run.sh"
echo "• Parar: Ctrl+C ou pkill -f telegram_api"
echo "• Logs: tail -f nohup.out"
echo "• Status: curl http://localhost:5000/api/status"
echo ""
echo -e "${CYAN}🌐 ACESSO EXTERNO (se necessário):${NC}"
echo "• Liberar firewall: ufw allow 5000"

# Detectar IP externo
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "SEU_IP_VPS")
echo "• Acesso externo: http://$EXTERNAL_IP:5000"
echo ""
log_info "Sistema instalado em: $(pwd)"
echo ""
echo -e "${GREEN}🎉 Para iniciar agora mesmo:${NC}"
echo -e "${YELLOW}cd $PROJECT_DIR && ./run.sh${NC}"

