#!/bin/bash

# Telegram SaaS Pro v4 - Instalador GitHub
# Versão: 4.0 Clean
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

# URLs do GitHub (substitua pelo seu repositório)
GITHUB_USER="Lucasfig199"
GITHUB_REPO="TEL-SAAS-3.0"
ZIP_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/raw/main/telegram-saas-integrado.zip"

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   log_warning "Este script não deve ser executado como root"
   log_info "Execute como usuário normal: curl -fsSL URL | bash"
   exit 1
fi

# Verificar sistema operacional
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "Este instalador é compatível apenas com Linux"
    exit 1
fi

log_info "Iniciando instalação do Telegram SaaS Pro v4..."
echo ""

# 1. Atualizar sistema
log_info "1/9 Atualizando sistema..."
sudo apt update -qq > /dev/null 2>&1
log_success "Sistema atualizado"

# 2. Instalar dependências do sistema
log_info "2/9 Instalando dependências do sistema..."
sudo apt install -y python3 python3-pip python3-venv curl wget unzip > /dev/null 2>&1
log_success "Dependências do sistema instaladas"

# 3. Verificar Python
log_info "3/9 Verificando Python..."
if ! command -v python3 &> /dev/null; then
    log_error "Python3 não encontrado"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
log_success "Python $PYTHON_VERSION encontrado"

# 4. Baixar arquivos do GitHub
log_info "4/9 Baixando arquivos do GitHub..."
if [ -d "telegram-saas-integrado" ]; then
    log_warning "Diretório telegram-saas-integrado já existe, removendo..."
    rm -rf telegram-saas-integrado
fi

wget -q "$ZIP_URL" -O telegram-saas-integrado.zip
if [ $? -ne 0 ]; then
    log_error "Falha ao baixar arquivos do GitHub"
    log_info "Verifique se a URL está correta: $ZIP_URL"
    exit 1
fi
log_success "Arquivos baixados do GitHub"

# 5. Extrair arquivos
log_info "5/9 Extraindo arquivos..."
unzip -q telegram-saas-integrado.zip
if [ $? -ne 0 ]; then
    log_error "Falha ao extrair arquivos"
    exit 1
fi

# Entrar no diretório extraído
cd telegram-saas-integrado
log_success "Arquivos extraídos"

# 6. Criar ambiente virtual
log_info "6/9 Criando ambiente virtual..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    log_success "Ambiente virtual criado"
else
    log_warning "Ambiente virtual já existe"
fi

# 7. Ativar ambiente virtual e instalar dependências Python
log_info "7/9 Instalando dependências Python..."
source venv/bin/activate

# Atualizar pip
pip install --upgrade pip > /dev/null 2>&1

# Instalar dependências uma por uma para melhor controle de erro
log_info "   Instalando Flask..."
pip install Flask==2.3.3 > /dev/null 2>&1

log_info "   Instalando Telethon..."
pip install Telethon==1.29.3 > /dev/null 2>&1

log_info "   Instalando requests..."
pip install requests==2.31.0 > /dev/null 2>&1

log_success "Dependências Python instaladas"

# 8. Verificar arquivos necessários
log_info "8/9 Verificando arquivos do projeto..."

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
        log_error "Arquivo necessário não encontrado: $file"
        exit 1
    fi
done

log_success "Todos os arquivos necessários encontrados"

# 9. Configurar permissões e iniciar
log_info "9/9 Configurando sistema..."
chmod +x run.sh 2>/dev/null || true
chmod 644 *.json 2>/dev/null || true
chmod 644 static/* 2>/dev/null || true

# Teste de funcionamento
python3 -c "
import flask
import telethon
import requests
import json
import os
print('✅ Todas as bibliotecas importadas com sucesso')
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
rm -f telegram-saas-integrado.zip

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
log_info "Sistema instalado em: $(pwd)/telegram-saas-integrado"
echo ""

