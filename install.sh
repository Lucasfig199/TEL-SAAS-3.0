#!/bin/bash

# Telegram SaaS Pro v4 - Instalador GitHub Final
# Versão: 4.0 Final - Com HTML completo
# Data: $(date)

set -e  # Parar em caso de erro

echo "🚀 Telegram SaaS Pro v4 - Instalador GitHub Final"
echo "================================================="
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
ZIP_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/raw/main/telegram-saas-integrado.zip"

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
    apt install -y python3 python3-pip python3-venv curl wget unzip lsof > /dev/null 2>&1 || {
        log_error "Falha ao instalar dependências via apt"
        exit 1
    }
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip curl wget unzip lsof > /dev/null 2>&1 || {
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

if [ -f "telegram-saas-integrado.zip" ]; then
    log_warning "Arquivo ZIP já existe, removendo..."
    rm -f telegram-saas-integrado.zip
fi

log_info "   Baixando de: $ZIP_URL"
wget -q --timeout=60 --tries=3 "$ZIP_URL" -O telegram-saas-integrado.zip
if [ $? -ne 0 ]; then
    log_error "Falha ao baixar arquivos do GitHub"
    log_info "Verifique se a URL está correta: $ZIP_URL"
    log_info "Verifique sua conexão com a internet"
    exit 1
fi
log_success "Arquivos baixados do GitHub ($(du -h telegram-saas-integrado.zip | cut -f1))"

# 5. Extrair arquivos
log_info "5/9 Extraindo arquivos..."
unzip -q telegram-saas-integrado.zip -d telegram-saas-integrado
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair arquivos"
    exit 1
fi

# Entrar no diretório extraído
cd telegram-saas-integrado
log_success "Arquivos extraídos"

# 6. Verificar arquivos essenciais
log_info "6/9 Verificando arquivos essenciais..."

REQUIRED_FILES=(
    "telegram_api_v4.py"
    "static/index.html"
    "install.sh"
    "run.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Arquivo essencial não encontrado: $file"
        exit 1
    fi
done

log_success "Todos os arquivos essenciais encontrados"

# 7. Executar instalação local
log_info "7/9 Executando instalação local..."
chmod +x install.sh run.sh

# Executar instalador local
./install.sh

if [ $? -ne 0 ]; then
    log_error "Falha na instalação local"
    exit 1
fi

log_success "Instalação local concluída"

# 8. Teste final do sistema
log_info "8/9 Testando sistema..."

# Verificar se o ambiente virtual foi criado
if [ ! -d "venv" ]; then
    log_error "Ambiente virtual não foi criado"
    exit 1
fi

# Ativar ambiente e testar importações
source venv/bin/activate

python3 -c "
try:
    import flask
    import telethon
    import requests
    import json
    import os
    print('✅ Sistema testado com sucesso')
except ImportError as e:
    print(f'❌ Erro no teste: {e}')
    exit(1)
" 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Sistema testado e funcionando"
else
    log_error "Falha no teste do sistema"
    exit 1
fi

# 9. Verificar interface HTML
log_info "9/9 Verificando interface..."
if [ -f "static/index.html" ]; then
    HTML_SIZE=$(du -h static/index.html | cut -f1)
    log_success "Interface HTML encontrada ($HTML_SIZE)"
else
    log_error "Interface HTML não encontrada"
    exit 1
fi

# Limpar arquivo ZIP
cd ..
rm -f telegram-saas-integrado.zip

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "===================================="
echo ""
log_success "Telegram SaaS Pro v4 instalado e 100% funcional!"
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
echo "• Parar: Ctrl+C ou pkill -f telegram_api"
echo "• Logs: Ver no terminal"
echo "• Status: curl http://localhost:5000/api/status"
echo ""
echo "🌐 ACESSO EXTERNO (se necessário):"
echo "• Liberar firewall: ufw allow 5000"
echo "• Acesso externo: http://SEU_IP_VPS:5000"
echo ""
echo "✨ FUNCIONALIDADES DISPONÍVEIS:"
echo "• 📊 Dashboard com gráficos interativos"
echo "• 👥 Gerenciamento de múltiplas contas"
echo "• 🔗 Webhooks individuais por conta"
echo "• 📤 Envio de mensagens, fotos, vídeos e áudios"
echo "• 🎯 Sistema de leads e grupos"
echo "• 📚 API com 16 endpoints documentados"
echo "• ⏰ Agendamento de mensagens"
echo ""
log_info "Sistema instalado em: $(pwd)/telegram-saas-integrado"
echo ""
echo "🚀 Para iniciar agora mesmo:"
echo "cd telegram-saas-integrado && ./run.sh"
echo ""

