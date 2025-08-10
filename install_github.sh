#!/bin/bash

# Telegram SaaS Pro v4 - Instalador GitHub (Corrigido)
# Versão: 4.0 Clean - Sem verificação de root
# Data: $(date)

set -e  # Parar em caso de erro

echo "🚀 Telegram SaaS Pro v4 - Instalador GitHub"
echo "============================================"
echo ""

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

# URLs do GitHub
GITHUB_USER="Lucasfig199"
GITHUB_REPO="TEL-SAAS-3.0"
ZIP_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/raw/main/telegram-saas-pro-v4-clean.zip"

# Verificar sistema operacional
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "Este instalador é compatível apenas com Linux"
    exit 1
fi

log_info "Iniciando instalação do Telegram SaaS Pro v4..."
echo ""

# 1. Atualizar sistema
log_info "1/9 Atualizando sistema..."
if command -v apt &> /dev/null; then
    apt update -qq > /dev/null 2>&1 || {
        log_warning "Falha ao atualizar repositórios, continuando..."
    }
    log_success "Sistema atualizado"
elif command -v yum &> /dev/null; then
    yum update -y -q > /dev/null 2>&1 || {
        log_warning "Falha ao atualizar repositórios, continuando..."
    }
    log_success "Sistema atualizado"
else
    log_warning "Gerenciador de pacotes não identificado, continuando..."
fi

# 2. Instalar dependências do sistema
log_info "2/9 Instalando dependências do sistema..."
if command -v apt &> /dev/null; then
    apt install -y python3 python3-pip python3-venv curl wget unzip > /dev/null 2>&1 || {
        log_error "Falha ao instalar dependências via apt"
        exit 1
    }
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip curl wget unzip > /dev/null 2>&1 || {
        log_error "Falha ao instalar dependências via yum"
        exit 1
    }
else
    log_error "Gerenciador de pacotes não suportado"
    exit 1
fi
log_success "Dependências do sistema instaladas"

# 3. Verificar Python
log_info "3/9 Verificando Python..."
if ! command -v python3 &> /dev/null; then
    log_error "Python3 não encontrado após instalação"
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>/dev/null | cut -d' ' -f2 | cut -d'.' -f1,2)
log_success "Python $PYTHON_VERSION encontrado"

# 4. Baixar arquivos do GitHub
log_info "4/9 Baixando arquivos do GitHub..."
if [ -d "telegram-saas-integrado" ]; then
    log_warning "Diretório telegram-saas-integrado já existe, removendo..."
    rm -rf telegram-saas-integrado
fi

if [ -f "telegram-saas-pro-v4-clean.zip" ]; then
    log_warning "Arquivo ZIP já existe, removendo..."
    rm -f telegram-saas-pro-v4-clean.zip
fi

log_info "   Baixando de: $ZIP_URL"
wget -q --timeout=30 --tries=3 "$ZIP_URL" -O telegram-saas-pro-v4-clean.zip
if [ $? -ne 0 ]; then
    log_error "Falha ao baixar arquivos do GitHub"
    log_info "Verifique se a URL está correta: $ZIP_URL"
    log_info "Verifique sua conexão com a internet"
    exit 1
fi
log_success "Arquivos baixados do GitHub"

# 5. Extrair arquivos
log_info "5/9 Extraindo arquivos..."
unzip -q telegram-saas-pro-v4-clean.zip -d telegram-saas-integrado
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair arquivos"
    exit 1
fi

# Entrar no diretório extraído
cd telegram-saas-integrado
log_success "Arquivos extraídos"

# 6. Verificar se pip3 está disponível
log_info "6/9 Verificando pip3..."
if ! command -v pip3 &> /dev/null; then
    log_warning "pip3 não encontrado, tentando instalar..."
    if command -v apt &> /dev/null; then
        apt install -y python3-pip > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y python3-pip > /dev/null 2>&1
    fi
    
    if ! command -v pip3 &> /dev/null; then
        log_error "Não foi possível instalar pip3"
        exit 1
    fi
fi
log_success "pip3 verificado"

# 7. Criar ambiente virtual
log_info "7/9 Criando ambiente virtual..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        log_error "Falha ao criar ambiente virtual"
        exit 1
    fi
    log_success "Ambiente virtual criado"
else
    log_warning "Ambiente virtual já existe"
fi

# 8. Ativar ambiente virtual e instalar dependências Python
log_info "8/9 Instalando dependências Python..."
source venv/bin/activate

# Atualizar pip
pip install --upgrade pip > /dev/null 2>&1 || {
    log_warning "Falha ao atualizar pip, continuando..."
}

# Instalar dependências uma por uma para melhor controle de erro
log_info "   Instalando Flask..."
pip install Flask==2.3.3 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_warning "Falha ao instalar Flask 2.3.3, tentando versão mais recente..."
    pip install Flask > /dev/null 2>&1 || {
        log_error "Falha ao instalar Flask"
        exit 1
    }
fi

log_info "   Instalando Telethon..."
pip install Telethon==1.29.3 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_warning "Falha ao instalar Telethon 1.29.3, tentando versão mais recente..."
    pip install Telethon > /dev/null 2>&1 || {
        log_error "Falha ao instalar Telethon"
        exit 1
    }
fi

log_info "   Instalando requests..."
pip install requests==2.31.0 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_warning "Falha ao instalar requests 2.31.0, tentando versão mais recente..."
    pip install requests > /dev/null 2>&1 || {
        log_error "Falha ao instalar requests"
        exit 1
    }
fi

log_success "Dependências Python instaladas"

# 9. Verificar arquivos necessários e configurar
log_info "9/9 Configurando sistema..."

REQUIRED_FILES=(
    "telegram_api_v4.py"
    "static/index.html"
    "accounts.json"
    "webhooks.json"
    "config.json"
    "scheduled_messages.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_warning "Arquivo $file não encontrado, criando..."
        case $file in
            "accounts.json")
                echo '[]' > "$file"
                ;;
            "webhooks.json")
                echo '{}' > "$file"
                ;;
            "config.json")
                echo '{"webhook_url": ""}' > "$file"
                ;;
            "scheduled_messages.json")
                echo '[]' > "$file"
                ;;
            "static/index.html")
                mkdir -p static
                echo '<h1>Interface não encontrada</h1>' > "$file"
                ;;
        esac
        log_success "Arquivo $file criado"
    fi
done

# Configurar permissões
chmod +x run.sh 2>/dev/null || true
chmod 644 *.json 2>/dev/null || true
chmod 644 static/* 2>/dev/null || true

# Teste de funcionamento
log_info "Testando instalação..."
python3 -c "
try:
    import flask
    import telethon
    import requests
    import json
    import os
    print('✅ Todas as bibliotecas importadas com sucesso')
except ImportError as e:
    print(f'❌ Erro de importação: {e}')
    exit(1)
" 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Teste de importação passou"
else
    log_error "Falha no teste de importação"
    exit 1
fi

# Verificar se o arquivo principal está válido
python3 -m py_compile telegram_api_v4.py 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Arquivo principal válido"
else
    log_error "Erro de sintaxe no arquivo principal"
    exit 1
fi

# Limpar arquivo ZIP
cd ..
rm -f telegram-saas-pro-v4-clean.zip

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "===================================="
echo ""
log_success "Telegram SaaS Pro v4 instalado e pronto para uso"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. cd telegram-saas-integrado"
echo "2. ./run.sh"
echo "3. Acesse: http://localhost:5000"
echo "4. Conecte suas contas na aba 'Conectar Conta'"
echo "5. Configure webhooks na aba 'Gerenciar Contas'"
echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "• Iniciar: ./run.sh"
echo "• Parar: pkill -f telegram_api"
echo "• Logs: tail -f nohup.out"
echo "• Status: curl http://localhost:5000/api/status"
echo ""
echo "🌐 ACESSO EXTERNO (se necessário):"
echo "• Liberar firewall: ufw allow 5000"
echo "• Acesso externo: http://SEU_IP_VPS:5000"
echo ""
log_info "Sistema instalado em: $(pwd)/telegram-saas-integrado"
echo ""
echo "🚀 Para iniciar agora mesmo:"
echo "cd telegram-saas-integrado && ./run.sh"
echo ""

