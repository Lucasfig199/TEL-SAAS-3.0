#!/bin/bash

# 🚀 Telegram SaaS Pro v4 - Instalador Corrigido
# Versão: 4.0 - Corrigida para VPS (SEM CONTA SARA MELO)

echo "🚀 Iniciando instalação do Telegram SaaS Pro v4..."

# Verificar se está executando como root ou com sudo
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Executando sem privilégios de root. Algumas operações podem falhar."
    echo "💡 Recomendado: sudo $0"
fi

# Atualizar sistema
echo "📦 Atualizando sistema..."
apt update -y

# Instalar dependências do sistema
echo "🔧 Instalando dependências do sistema..."
apt install -y python3 python3-pip wget unzip curl

# Verificar se Python3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Erro: Python3 não foi instalado corretamente"
    exit 1
fi

# Verificar se pip3 está instalado
if ! command -v pip3 &> /dev/null; then
    echo "❌ Erro: pip3 não foi instalado corretamente"
    exit 1
fi

echo "✅ Python3 e pip3 instalados com sucesso"

# Baixar arquivo ZIP do GitHub (VERSÃO CORRIGIDA)
echo "📥 Baixando Telegram SaaS do GitHub (versão sem conta hardcoded)..."
if [ -f "telegram-saas-integrado.zip" ]; then
    echo "📁 Arquivo ZIP já existe, removendo versão antiga..."
    rm -f telegram-saas-integrado.zip
fi

wget -O telegram-saas-integrado.zip "https://github.com/Lucasfig199/TEL-SAAS-3.0/raw/main/telegram-saas-integrado-corrigido.zip"

if [ ! -f "telegram-saas-integrado.zip" ]; then
    echo "❌ Erro: Não foi possível baixar o arquivo ZIP"
    echo "🔍 Verifique se o link está correto no GitHub"
    exit 1
fi

echo "✅ Arquivo ZIP baixado com sucesso"

# Remover diretório existente se houver
if [ -d "telegram-saas-integrado" ]; then
    echo "🗑️  Removendo instalação anterior..."
    rm -rf telegram-saas-integrado
fi

# Extrair arquivo ZIP
echo "📂 Extraindo arquivos..."
unzip -q telegram-saas-integrado.zip

if [ ! -d "telegram-saas-integrado" ]; then
    echo "❌ Erro: Não foi possível extrair o arquivo ZIP"
    exit 1
fi

echo "✅ Arquivos extraídos com sucesso"

# Entrar no diretório
cd telegram-saas-integrado

# Verificar se os arquivos principais existem
if [ ! -f "telegram_api_v4.py" ]; then
    echo "❌ Erro: Arquivo telegram_api_v4.py não encontrado"
    exit 1
fi

echo "✅ Arquivos principais verificados"

# Instalar dependências Python
echo "🐍 Instalando dependências Python..."

# Instalar dependências uma por uma para melhor controle
pip3 install Flask==2.3.3
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar Flask"
    exit 1
fi

pip3 install Telethon==1.29.3
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar Telethon"
    exit 1
fi

pip3 install requests==2.31.0
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar requests"
    exit 1
fi

echo "✅ Dependências Python instaladas com sucesso"

# Criar arquivos de configuração se não existirem (GARANTIR QUE ESTÃO VAZIOS)
echo "⚙️  Criando arquivos de configuração limpos..."

# Forçar criação de arquivos vazios
echo '{"webhook_url": ""}' > config.json
echo '[]' > accounts.json
echo '{}' > webhooks.json
echo '[]' > scheduled_messages.json

echo "✅ Arquivos de configuração criados (LIMPOS - sem dados de exemplo)"

# Dar permissões aos scripts
echo "🔐 Configurando permissões..."
if [ -f "run.sh" ]; then
    chmod +x run.sh
fi

if [ -f "install.sh" ]; then
    chmod +x install.sh
fi

echo "✅ Permissões configuradas"

# Verificar se tudo está pronto
echo "🔍 Verificando instalação..."

# Verificar dependências Python
python3 -c "import flask, telethon, requests; print('✅ Todas as dependências Python estão OK')" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Erro: Algumas dependências Python não foram instaladas corretamente"
    echo "🔧 Tentando reinstalar..."
    pip3 install --force-reinstall Flask==2.3.3 Telethon==1.29.3 requests==2.31.0
fi

echo "✅ Instalação concluída!"

# Iniciar o sistema
echo "🚀 Iniciando Telegram SaaS..."

# Matar processos anteriores se existirem
pkill -f telegram_api_v4 2>/dev/null

# Iniciar em background
nohup python3 telegram_api_v4.py > nohup.out 2>&1 &

# Aguardar alguns segundos para o sistema iniciar
sleep 5

# Verificar se está rodando
if pgrep -f telegram_api_v4 > /dev/null; then
    echo "✅ Sistema iniciado com sucesso!"
    echo ""
    echo "🎉 INSTALAÇÃO CONCLUÍDA!"
    echo ""
    echo "🧹 CORREÇÃO APLICADA:"
    echo "   ❌ Removida conta hardcoded Sara Melo"
    echo "   ✅ Sistema inicia 100% limpo"
    echo "   ✅ Mensagem 'Nenhuma conta conectada' será exibida"
    echo ""
    echo "📊 Para acessar o sistema:"
    echo "   http://localhost:5000"
    echo "   http://$(hostname -I | awk '{print $1}'):5000"
    echo ""
    echo "📋 Para ver logs:"
    echo "   tail -f nohup.out"
    echo ""
    echo "🔧 Para parar o sistema:"
    echo "   pkill -f telegram_api_v4"
    echo ""
    echo "🔄 Para reiniciar:"
    echo "   ./run.sh"
    echo ""
    echo "🎯 Funcionalidades disponíveis:"
    echo "   • Dashboard com gráficos"
    echo "   • Gerenciamento de múltiplas contas"
    echo "   • Webhooks individuais por conta"
    echo "   • Envio de mensagens, fotos, vídeos, áudios"
    echo "   • Adição de leads em grupos"
    echo "   • Criação de grupos para leads"
    echo "   • Agendamento de mensagens"
    echo "   • API completa com 16 endpoints"
    echo ""
    echo "✨ AGORA SEM CONTA FANTASMA SARA MELO!"
    echo ""
else
    echo "❌ Erro: Sistema não iniciou corretamente"
    echo "📋 Verificar logs:"
    echo "   cat nohup.out"
    echo ""
    echo "🔧 Tentar iniciar manualmente:"
    echo "   python3 telegram_api_v4.py"
fi

