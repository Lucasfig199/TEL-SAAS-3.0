#!/bin/bash

echo "🚀 Instalando Telegram SaaS Pro v4..."

# Verificar se Python3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não encontrado. Instalando..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

# Verificar se pip está instalado
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 não encontrado. Instalando..."
    sudo apt install -y python3-pip
fi

# Instalar dependências
echo "📦 Instalando dependências Python..."
pip3 install -r requirements.txt

# Criar arquivos de configuração se não existirem
if [ ! -f "config.json" ]; then
    echo "⚙️ Criando arquivo de configuração..."
    echo '{"webhook_url": ""}' > config.json
fi

if [ ! -f "accounts.json" ]; then
    echo "👥 Criando arquivo de contas..."
    echo '[]' > accounts.json
fi

if [ ! -f "webhooks.json" ]; then
    echo "🔗 Criando arquivo de webhooks..."
    echo '{}' > webhooks.json
fi

if [ ! -f "scheduled_messages.json" ]; then
    echo "⏰ Criando arquivo de mensagens agendadas..."
    echo '[]' > scheduled_messages.json
fi

# Tornar o script executável
chmod +x run.sh

echo "✅ Instalação concluída!"
echo ""
echo "🎯 Para iniciar o SaaS:"
echo "   ./run.sh"
echo ""
echo "🌐 Acesse: http://localhost:5000"
echo ""
echo "📚 Funcionalidades disponíveis:"
echo "   • Dashboard com gráficos"
echo "   • Gerenciamento de múltiplas contas"
echo "   • Webhooks individuais por conta"
echo "   • Envio de mensagens, fotos, vídeos, áudios"
echo "   • Adição de leads em grupos"
echo "   • Criação de grupos para leads"
echo "   • Agendamento de mensagens"
echo "   • API completa com 16 endpoints"
echo ""

