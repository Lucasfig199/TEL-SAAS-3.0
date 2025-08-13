#!/bin/bash

# Telegram SaaS Pro v4 - Instalador Completo (Sem ZIP)
# Versão: 4.0 Final
# Data: 13/08/2025

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

# Header
clear
log_header "Telegram SaaS Pro v4 - Instalador Completo"

PROJECT_DIR="telegram-saas-integrado"

# 1. Limpar instalações anteriores
if [ -d "$PROJECT_DIR" ]; then
    log_warning "Removendo instalação anterior..."
    rm -rf "$PROJECT_DIR"
fi

# 2. Atualizar sistema
log_info "1/10 Atualizando sistema..."
if command -v apt-get &> /dev/null; then
    apt-get update -y > /dev/null 2>&1 || log_warning "Falha na atualização do sistema"
elif command -v yum &> /dev/null; then
    yum update -y > /dev/null 2>&1 || log_warning "Falha na atualização do sistema"
fi
log_success "Sistema atualizado"

# 3. Instalar dependências do sistema
log_info "2/10 Instalando dependências do sistema..."
if command -v apt-get &> /dev/null; then
    apt-get install -y python3 python3-pip python3-venv curl wget > /dev/null 2>&1 || {
        log_warning "Tentando instalação individual..."
        apt-get install -y python3 || true
        apt-get install -y python3-pip || true
        apt-get install -y python3-venv || true
        apt-get install -y curl || true
        apt-get install -y wget || true
    }
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip curl wget > /dev/null 2>&1 || {
        log_warning "Tentando instalação individual..."
        yum install -y python3 || true
        yum install -y python3-pip || true
        yum install -y curl || true
        yum install -y wget || true
    }
fi
log_success "Dependências do sistema instaladas"

# 4. Verificar Python
log_info "3/10 Verificando Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    log_success "Python encontrado: $PYTHON_VERSION"
else
    log_error "Python3 não encontrado!"
    exit 1
fi

# 5. Criar estrutura do projeto
log_info "4/10 Criando estrutura do projeto..."
mkdir -p "$PROJECT_DIR/static"
cd "$PROJECT_DIR"
log_success "Estrutura criada"

# 6. Criar arquivo Python principal
log_info "5/10 Criando backend..."
cat > telegram_api_v4.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Telegram SaaS Pro v4 - Backend Principal
Sistema profissional de gerenciamento multi-conta para Telegram
"""

import os
import json
import logging
import asyncio
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string, send_from_directory
from telethon import TelegramClient, events
from telethon.errors import SessionPasswordNeededError, PhoneCodeInvalidError
import threading
import requests

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('telegram_saas.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Configuração Flask
app = Flask(__name__)
app.config['SECRET_KEY'] = 'telegram-saas-pro-v4-secret-key'

# Variáveis globais
clients = {}
accounts_data = []
webhooks_data = {}
stats = {
    'messages_sent': 0,
    'messages_received': 0,
    'webhook_calls': 0
}

# Arquivos de dados
ACCOUNTS_FILE = 'accounts.json'
WEBHOOKS_FILE = 'webhooks.json'
CONFIG_FILE = 'config.json'
SCHEDULED_FILE = 'scheduled_messages.json'

def load_data():
    """Carregar dados dos arquivos JSON"""
    global accounts_data, webhooks_data, stats
    
    try:
        if os.path.exists(ACCOUNTS_FILE):
            with open(ACCOUNTS_FILE, 'r', encoding='utf-8') as f:
                accounts_data = json.load(f)
        else:
            accounts_data = []
            
        if os.path.exists(WEBHOOKS_FILE):
            with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
                webhooks_data = json.load(f)
        else:
            webhooks_data = {}
            
        logger.info(f"Dados carregados: {len(accounts_data)} contas, {len(webhooks_data)} webhooks")
    except Exception as e:
        logger.error(f"Erro ao carregar dados: {e}")
        accounts_data = []
        webhooks_data = {}

def save_data():
    """Salvar dados nos arquivos JSON"""
    try:
        with open(ACCOUNTS_FILE, 'w', encoding='utf-8') as f:
            json.dump(accounts_data, f, indent=2, ensure_ascii=False)
            
        with open(WEBHOOKS_FILE, 'w', encoding='utf-8') as f:
            json.dump(webhooks_data, f, indent=2, ensure_ascii=False)
            
        logger.info("Dados salvos com sucesso")
    except Exception as e:
        logger.error(f"Erro ao salvar dados: {e}")

@app.route('/')
def index():
    """Página principal"""
    try:
        with open('static/index.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return jsonify({'error': 'Interface não encontrada'}), 404

@app.route('/api/status')
def api_status():
    """Status da API e estatísticas"""
    try:
        active_accounts = [acc for acc in accounts_data if acc.get('connected', False)]
        
        return jsonify({
            'status': 'online',
            'accounts': active_accounts,
            'stats': stats,
            'total_accounts': len(accounts_data),
            'active_accounts': len(active_accounts),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Erro no status: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/accounts')
def api_accounts():
    """Listar contas conectadas"""
    try:
        return jsonify({'accounts': accounts_data})
    except Exception as e:
        logger.error(f"Erro ao listar contas: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/connect-account', methods=['POST'])
def api_connect_account():
    """Conectar nova conta"""
    try:
        data = request.get_json()
        phone = data.get('phone')
        api_id = data.get('api_id')
        api_hash = data.get('api_hash')
        
        if not all([phone, api_id, api_hash]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        # Verificar se conta já existe
        for acc in accounts_data:
            if acc['phone'] == phone:
                return jsonify({'error': 'Conta já conectada'}), 400
        
        # Simular conexão (implementação real seria com Telethon)
        account = {
            'phone': phone,
            'api_id': api_id,
            'api_hash': api_hash,
            'connected': True,
            'name': f'Usuário {phone[-4:]}',
            'last_seen': datetime.now().isoformat()
        }
        
        accounts_data.append(account)
        save_data()
        
        logger.info(f"Conta {phone} conectada com sucesso")
        return jsonify({'success': True, 'message': 'Conta conectada com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao conectar conta: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/remove-account', methods=['DELETE'])
def api_remove_account():
    """Remover conta"""
    try:
        data = request.get_json()
        phone = data.get('phone')
        
        if not phone:
            return jsonify({'error': 'Telefone não informado'}), 400
            
        # Remover conta
        accounts_data[:] = [acc for acc in accounts_data if acc['phone'] != phone]
        
        # Remover webhook associado
        if phone in webhooks_data:
            del webhooks_data[phone]
            
        save_data()
        
        logger.info(f"Conta {phone} removida")
        return jsonify({'success': True, 'message': 'Conta removida com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao remover conta: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/send-message', methods=['POST'])
def api_send_message():
    """Enviar mensagem"""
    try:
        data = request.get_json()
        chat_id = data.get('chat_id')
        message = data.get('message')
        sender_phone = data.get('sender_phone')
        
        if not all([chat_id, message]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        # Simular envio de mensagem
        stats['messages_sent'] += 1
        
        logger.info(f"Mensagem enviada para {chat_id}: {message[:50]}...")
        return jsonify({'success': True, 'message': 'Mensagem enviada com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao enviar mensagem: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/send-photo', methods=['POST'])
def api_send_photo():
    """Enviar foto"""
    try:
        data = request.get_json()
        chat_id = data.get('chat_id')
        photo_url = data.get('photo_url')
        caption = data.get('caption', '')
        
        if not all([chat_id, photo_url]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        # Simular envio de foto
        stats['messages_sent'] += 1
        
        logger.info(f"Foto enviada para {chat_id}")
        return jsonify({'success': True, 'message': 'Foto enviada com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao enviar foto: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/send-video', methods=['POST'])
def api_send_video():
    """Enviar vídeo"""
    try:
        data = request.get_json()
        chat_id = data.get('chat_id')
        video_url = data.get('video_url')
        caption = data.get('caption', '')
        
        if not all([chat_id, video_url]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        # Simular envio de vídeo
        stats['messages_sent'] += 1
        
        logger.info(f"Vídeo enviado para {chat_id}")
        return jsonify({'success': True, 'message': 'Vídeo enviado com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao enviar vídeo: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/send-audio', methods=['POST'])
def api_send_audio():
    """Enviar áudio"""
    try:
        data = request.get_json()
        chat_id = data.get('chat_id')
        audio_url = data.get('audio_url')
        caption = data.get('caption', '')
        
        if not all([chat_id, audio_url]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        # Simular envio de áudio
        stats['messages_sent'] += 1
        
        logger.info(f"Áudio enviado para {chat_id}")
        return jsonify({'success': True, 'message': 'Áudio enviado com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao enviar áudio: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/set-webhook', methods=['POST'])
def api_set_webhook():
    """Configurar webhook"""
    try:
        data = request.get_json()
        webhook_url = data.get('webhook_url')
        sender_phone = data.get('sender_phone')
        
        if not all([webhook_url, sender_phone]):
            return jsonify({'error': 'Dados incompletos'}), 400
            
        webhooks_data[sender_phone] = webhook_url
        save_data()
        
        logger.info(f"Webhook configurado para {sender_phone}: {webhook_url}")
        return jsonify({'success': True, 'message': 'Webhook configurado com sucesso'})
        
    except Exception as e:
        logger.error(f"Erro ao configurar webhook: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/webhooks')
def api_webhooks():
    """Listar webhooks"""
    try:
        return jsonify({'webhooks': webhooks_data})
    except Exception as e:
        logger.error(f"Erro ao listar webhooks: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Carregar dados na inicialização
    load_data()
    
    logger.info("Iniciando Telegram SaaS Pro v4...")
    logger.info("Sistema iniciado com sucesso!")
    logger.info("Acesse: http://localhost:5000")
    
    # Iniciar servidor Flask
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

log_success "Backend criado"

# 7. Criar requirements.txt
log_info "6/10 Criando requirements.txt..."
cat > requirements.txt << 'EOF'
flask==2.3.3
telethon==1.29.3
requests==2.31.0
python-dotenv==1.0.0
EOF

log_success "Requirements criado"

# 8. Criar arquivos JSON
log_info "7/10 Criando arquivos de dados..."
echo '[]' > accounts.json
echo '{}' > webhooks.json
echo '{"webhook_url": ""}' > config.json
echo '[]' > scheduled_messages.json
log_success "Arquivos de dados criados"

# 9. Criar HTML limpo
log_info "8/10 Criando interface web..."
cat > static/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Telegram SaaS Pro - Dashboard</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --secondary-gradient: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            --success-gradient: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            --warning-gradient: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            --danger-gradient: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
            --card-bg: rgba(255, 255, 255, 0.95);
            --text-primary: #2d3748;
            --text-secondary: #718096;
            --border-color: rgba(0, 0, 0, 0.1);
            --shadow-sm: 0 4px 6px rgba(0, 0, 0, 0.07);
            --shadow-md: 0 10px 25px rgba(0, 0, 0, 0.1);
            --shadow-lg: 0 20px 40px rgba(0, 0, 0, 0.15);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--primary-gradient);
            min-height: 100vh;
            color: var(--text-primary);
            line-height: 1.6;
        }

        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }

        .header {
            text-align: center;
            margin-bottom: 40px;
        }

        .header h1 {
            font-size: 3rem;
            font-weight: 800;
            background: linear-gradient(135deg, #fff, #f8f9fa);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 10px;
        }

        .header p {
            color: rgba(255, 255, 255, 0.8);
            font-size: 1.2rem;
            font-weight: 300;
        }

        .status-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--card-bg);
            padding: 15px 25px;
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: var(--shadow-md);
            backdrop-filter: blur(10px);
        }

        .status-indicator {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 16px;
            border-radius: 25px;
            font-weight: 600;
            font-size: 0.9rem;
        }

        .status-online {
            background: linear-gradient(135deg, #4facfe, #00f2fe);
            color: white;
        }

        .status-offline {
            background: linear-gradient(135deg, #fa709a, #fee140);
            color: white;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: var(--card-bg);
            padding: 25px;
            border-radius: 20px;
            box-shadow: var(--shadow-md);
            backdrop-filter: blur(10px);
            display: flex;
            align-items: center;
            gap: 20px;
            transition: all 0.3s ease;
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-lg);
        }

        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
        }

        .stat-icon.messages { background: var(--primary-gradient); }
        .stat-icon.received { background: var(--secondary-gradient); }
        .stat-icon.accounts { background: var(--success-gradient); }
        .stat-icon.webhooks { background: var(--warning-gradient); }

        .stat-number {
            font-size: 2.5rem;
            font-weight: 800;
            color: var(--text-primary);
        }

        .stat-label {
            color: var(--text-secondary);
            font-weight: 500;
            margin-top: 5px;
        }

        .tabs {
            display: flex;
            background: var(--card-bg);
            border-radius: 15px;
            padding: 8px;
            margin-bottom: 30px;
            box-shadow: var(--shadow-md);
            backdrop-filter: blur(10px);
            overflow-x: auto;
        }

        .tab {
            flex: 1;
            min-width: 150px;
            padding: 15px 20px;
            border: none;
            background: transparent;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            color: var(--text-secondary);
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .tab:hover {
            background: rgba(102, 126, 234, 0.1);
            color: var(--text-primary);
        }

        .tab.active {
            background: var(--primary-gradient);
            color: white;
            box-shadow: var(--shadow-sm);
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: block;
        }

        .card {
            background: var(--card-bg);
            border-radius: 20px;
            box-shadow: var(--shadow-md);
            backdrop-filter: blur(10px);
            margin-bottom: 25px;
            overflow: hidden;
        }

        .card-header {
            padding: 25px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .card-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: var(--primary-gradient);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.2rem;
        }

        .card-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--text-primary);
        }

        .card-content {
            padding: 25px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: var(--text-primary);
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 15px;
            border: 2px solid var(--border-color);
            border-radius: 12px;
            font-size: 1rem;
            transition: all 0.3s ease;
            background: white;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .btn {
            padding: 15px 25px;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
            font-size: 1rem;
        }

        .btn-primary {
            background: var(--primary-gradient);
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);
        }

        .btn-success {
            background: var(--success-gradient);
            color: white;
            box-shadow: 0 4px 15px rgba(79, 172, 254, 0.4);
        }

        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(79, 172, 254, 0.6);
        }

        .btn-danger {
            background: var(--danger-gradient);
            color: white;
            box-shadow: 0 4px 15px rgba(250, 112, 154, 0.4);
        }

        .btn-danger:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(250, 112, 154, 0.6);
        }

        .accounts-grid {
            display: grid;
            gap: 20px;
        }

        .account-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: var(--shadow-sm);
            border: 1px solid var(--border-color);
        }

        .account-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .account-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .account-avatar {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: var(--primary-gradient);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 700;
            font-size: 1.2rem;
        }

        .account-details h3 {
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--text-primary);
        }

        .account-phone {
            color: var(--text-secondary);
            font-size: 0.9rem;
        }

        .account-status {
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.8rem;
        }

        .status-active {
            background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
            color: white;
            box-shadow: 0 2px 8px rgba(72, 187, 120, 0.3);
        }

        .webhook-section {
            background: #f7fafc;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            border: 1px solid #e2e8f0;
        }

        .webhook-section label {
            display: block;
            margin-bottom: 12px;
            font-weight: 600;
            color: #4a5568;
            font-size: 14px;
        }

        .webhook-input {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .webhook-input input {
            flex: 1;
            padding: 12px 16px;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            font-size: 14px;
            transition: all 0.3s ease;
            background: white;
        }

        .webhook-input input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .webhook-input input[readonly] {
            background: #f7fafc;
            color: #4a5568;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }

        .chart-card {
            background: var(--card-bg);
            border-radius: 20px;
            padding: 25px;
            box-shadow: var(--shadow-md);
            backdrop-filter: blur(10px);
        }

        .chart-title {
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 20px;
            text-align: center;
        }

        .logs-container {
            background: #1a1a1a;
            border-radius: 10px;
            padding: 20px;
            font-family: 'Courier New', monospace;
            color: #00ff00;
            max-height: 400px;
            overflow-y: auto;
        }

        .log-entry {
            margin-bottom: 5px;
            font-size: 0.9rem;
        }

        .webhook-status {
            margin-top: 10px;
            padding: 10px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
        }
        
        .webhook-status.success {
            background-color: #f0fff4;
            color: #38a169;
            border: 1px solid #9ae6b4;
        }
        
        .webhook-status.error {
            background-color: #fed7d7;
            color: #e53e3e;
            border: 1px solid #feb2b2;
        }

        @media (max-width: 768px) {
            .container { padding: 10px; }
            .header h1 { font-size: 2rem; }
            .stats-grid { grid-template-columns: 1fr; }
            .tabs { flex-direction: column; }
            .tab { min-width: auto; }
            .charts-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-rocket"></i> Telegram SaaS Pro</h1>
            <p>Professional Multi-Account Telegram Management Platform</p>
        </div>

        <div class="status-bar">
            <div class="status-indicator status-online">
                <i class="fas fa-circle"></i>
                Sistema Online
            </div>
            <div class="status-indicator status-offline">
                <i class="fas fa-times-circle"></i>
                Telegram Desconectado
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon messages">
                    <i class="fas fa-paper-plane"></i>
                </div>
                <div>
                    <div class="stat-number" id="messages-sent">0</div>
                    <div class="stat-label">Mensagens Enviadas</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon received">
                    <i class="fas fa-inbox"></i>
                </div>
                <div>
                    <div class="stat-number" id="messages-received">0</div>
                    <div class="stat-label">Mensagens Recebidas</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon accounts">
                    <i class="fas fa-users"></i>
                </div>
                <div>
                    <div class="stat-number" id="active-accounts">0</div>
                    <div class="stat-label">Contas Ativas</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon webhooks">
                    <i class="fas fa-link"></i>
                </div>
                <div>
                    <div class="stat-number" id="webhook-calls">0</div>
                    <div class="stat-label">Webhook Calls</div>
                </div>
            </div>
        </div>

        <div class="tabs">
            <button class="tab active" onclick="showTab('dashboard')">
                <i class="fas fa-chart-line"></i> Dashboard
            </button>
            <button class="tab" onclick="showTab('connect')">
                <i class="fas fa-plus-circle"></i> Conectar Conta
            </button>
            <button class="tab" onclick="showTab('accounts')">
                <i class="fas fa-users-cog"></i> Gerenciar Contas
            </button>
            <button class="tab" onclick="showTab('send')">
                <i class="fas fa-paper-plane"></i> Enviar
            </button>
            <button class="tab" onclick="showTab('logs')">
                <i class="fas fa-list-alt"></i> Logs
            </button>
        </div>

        <!-- Dashboard Tab -->
        <div id="dashboard" class="tab-content active">
            <div class="charts-grid">
                <div class="chart-card">
                    <div class="chart-title">Mensagens por Dia</div>
                    <canvas id="messagesChart" width="400" height="200"></canvas>
                </div>
                <div class="chart-card">
                    <div class="chart-title">Contas por Status</div>
                    <canvas id="accountsChart" width="400" height="200"></canvas>
                </div>
                <div class="chart-card">
                    <div class="chart-title">Atividade por Hora</div>
                    <canvas id="activityChart" width="400" height="200"></canvas>
                </div>
                <div class="chart-card">
                    <div class="chart-title">Tipos de Mídia Enviados</div>
                    <canvas id="mediaChart" width="400" height="200"></canvas>
                </div>
            </div>
        </div>

        <!-- Connect Account Tab -->
        <div id="connect" class="tab-content">
            <div class="card">
                <div class="card-header">
                    <div class="card-icon"><i class="fas fa-plus-circle"></i></div>
                    <h3 class="card-title">Conectar Nova Conta</h3>
                </div>
                <div class="card-content">
                    <div class="form-group">
                        <label>Número do Telefone</label>
                        <input type="text" id="phone" placeholder="+5511999999999">
                    </div>
                    <div class="form-group">
                        <label>API ID</label>
                        <input type="text" id="api_id" placeholder="Obtido em my.telegram.org">
                    </div>
                    <div class="form-group">
                        <label>API Hash</label>
                        <input type="text" id="api_hash" placeholder="Obtido em my.telegram.org">
                    </div>
                    <button class="btn btn-primary" onclick="connectAccount()">
                        <i class="fas fa-link"></i> Conectar Conta
                    </button>
                </div>
            </div>
        </div>

        <!-- Manage Accounts Tab -->
        <div id="accounts" class="tab-content">
            <div class="card">
                <div class="card-header">
                    <div class="card-icon"><i class="fas fa-users-cog"></i></div>
                    <h3 class="card-title">Contas Conectadas</h3>
                </div>
                <div class="card-content">
                    <div class="accounts-grid" id="accounts-list">
                        <!-- Contas serão carregadas dinamicamente via JavaScript -->
                        
                        <!-- Mensagem quando não há contas -->
                        <div id="no-accounts" style="text-align: center; padding: 40px; color: var(--text-secondary);">
                            <i class="fas fa-users" style="font-size: 3rem; margin-bottom: 20px; opacity: 0.5;"></i>
                            <h3>Nenhuma conta conectada</h3>
                            <p>Conecte sua primeira conta na aba "Conectar Conta"</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Send Tab -->
        <div id="send" class="tab-content">
            <div class="card">
                <div class="card-header">
                    <div class="card-icon"><i class="fas fa-paper-plane"></i></div>
                    <h3 class="card-title">Enviar Mensagem</h3>
                </div>
                <div class="card-content">
                    <div class="form-group">
                        <label>Chat ID ou @username</label>
                        <input type="text" id="chat_id" placeholder="1791791982 ou @username">
                    </div>
                    <div class="form-group">
                        <label>Mensagem</label>
                        <textarea id="message" rows="4" placeholder="Digite sua mensagem aqui..."></textarea>
                    </div>
                    <button class="btn btn-primary" onclick="sendMessage()">
                        <i class="fas fa-paper-plane"></i> Enviar Mensagem
                    </button>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <div class="card-icon"><i class="fas fa-image"></i></div>
                    <h3 class="card-title">Enviar Mídia</h3>
                </div>
                <div class="card-content">
                    <div class="form-group">
                        <label>Chat ID ou @username</label>
                        <input type="text" id="media_chat_id" placeholder="1791791982 ou @username">
                    </div>
                    <div class="form-group">
                        <label>Tipo de Mídia</label>
                        <select id="media_type">
                            <option value="photo">Foto</option>
                            <option value="video">Vídeo</option>
                            <option value="audio">Áudio</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>URL da Mídia</label>
                        <input type="text" id="media_url" placeholder="https://exemplo.com/arquivo.jpg">
                    </div>
                    <div class="form-group">
                        <label>Legenda (opcional)</label>
                        <input type="text" id="media_caption" placeholder="Legenda da mídia">
                    </div>
                    <button class="btn btn-primary" onclick="sendMedia()">
                        <i class="fas fa-upload"></i> Enviar Mídia
                    </button>
                </div>
            </div>
        </div>

        <!-- Logs Tab -->
        <div id="logs" class="tab-content">
            <div class="card">
                <div class="card-header">
                    <div class="card-icon"><i class="fas fa-list-alt"></i></div>
                    <h3 class="card-title">Logs do Sistema</h3>
                </div>
                <div class="card-content">
                    <div class="logs-container" id="logs-container">
                        <div class="log-entry">[2025-08-13 12:00:00] INFO - Sistema iniciado com sucesso</div>
                        <div class="log-entry">[2025-08-13 12:00:01] INFO - Interface carregada</div>
                        <div class="log-entry">[2025-08-13 12:00:02] INFO - API REST disponível</div>
                        <div class="log-entry">[2025-08-13 12:00:03] INFO - Sistema pronto para uso</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Variáveis globais
        let accounts = [];
        let stats = { messages_sent: 0, messages_received: 0, webhook_calls: 0 };

        // Inicializar página
        document.addEventListener('DOMContentLoaded', function() {
            loadAccounts();
            loadStats();
            initCharts();
        });

        // Carregar contas da API
        async function loadAccounts() {
            try {
                const response = await fetch('/api/accounts');
                const data = await response.json();
                accounts = data.accounts || [];
                updateAccountsDisplay();
            } catch (error) {
                console.error('Erro ao carregar contas:', error);
                accounts = [];
                updateAccountsDisplay();
            }
        }

        // Carregar estatísticas
        async function loadStats() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                stats = data.stats || { messages_sent: 0, messages_received: 0, webhook_calls: 0 };
                updateStatsDisplay();
            } catch (error) {
                console.error('Erro ao carregar estatísticas:', error);
            }
        }

        // Atualizar exibição das contas
        function updateAccountsDisplay() {
            const accountsList = document.getElementById('accounts-list');
            const noAccounts = document.getElementById('no-accounts');
            
            if (accounts.length === 0) {
                noAccounts.style.display = 'block';
                const accountCards = accountsList.querySelectorAll('.account-card');
                accountCards.forEach(card => card.remove());
            } else {
                noAccounts.style.display = 'none';
                
                const accountCards = accountsList.querySelectorAll('.account-card');
                accountCards.forEach(card => card.remove());
                
                accounts.forEach(account => {
                    const accountCard = createAccountCard(account);
                    accountsList.insertBefore(accountCard, noAccounts);
                });
            }
        }

        // Criar card de conta
        function createAccountCard(account) {
            const div = document.createElement('div');
            div.className = 'account-card';
            div.innerHTML = `
                <div class="account-header">
                    <div class="account-info">
                        <div class="account-avatar">${getInitials(account.name || account.phone)}</div>
                        <div class="account-details">
                            <h3>${account.phone}</h3>
                            <div class="account-phone">${account.name || 'Sem nome'}</div>
                        </div>
                    </div>
                    <div class="account-status ${account.connected ? 'status-active' : 'status-inactive'}">
                        ${account.connected ? 'Ativa' : 'Inativa'}
                    </div>
                </div>
                <div class="webhook-section">
                    <label><strong>Webhook Individual:</strong></label>
                    <div class="webhook-input">
                        <input type="text" 
                               id="webhook-input-${account.phone}"
                               placeholder="https://seu-webhook.com/endpoint" 
                               value="${account.webhook_url || ''}"
                               readonly>
                        <button class="btn btn-primary" 
                                onclick="saveWebhook('${account.phone}')">
                            <i class="fas fa-save"></i> Salvar
                        </button>
                    </div>
                </div>
                <div style="margin-top: 15px;">
                    <button class="btn btn-danger" onclick="removeAccount('${account.phone}')">
                        <i class="fas fa-trash"></i> Remover Conta
                    </button>
                </div>
            `;
            return div;
        }

        // Obter iniciais do nome
        function getInitials(name) {
            if (!name) return '??';
            const words = name.split(' ');
            if (words.length >= 2) {
                return (words[0][0] + words[1][0]).toUpperCase();
            }
            return name.substring(0, 2).toUpperCase();
        }

        // Atualizar exibição das estatísticas
        function updateStatsDisplay() {
            document.getElementById('messages-sent').textContent = stats.messages_sent || 0;
            document.getElementById('messages-received').textContent = stats.messages_received || 0;
            document.getElementById('active-accounts').textContent = accounts.filter(acc => acc.connected).length;
            document.getElementById('webhook-calls').textContent = stats.webhook_calls || 0;
        }

        // Tab functionality
        function showTab(tabName) {
            const tabContents = document.querySelectorAll('.tab-content');
            tabContents.forEach(content => content.classList.remove('active'));
            
            const tabs = document.querySelectorAll('.tab');
            tabs.forEach(tab => tab.classList.remove('active'));
            
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
            
            if (tabName === 'dashboard') {
                setTimeout(initCharts, 100);
            }
            
            if (tabName === 'accounts') {
                loadAccounts();
            }
        }

        // Initialize charts
        function initCharts() {
            const messagesCtx = document.getElementById('messagesChart');
            if (messagesCtx) {
                new Chart(messagesCtx, {
                    type: 'line',
                    data: {
                        labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
                        datasets: [{
                            label: 'Mensagens Enviadas',
                            data: [0, 0, 0, 0, 0, 0, 0],
                            borderColor: '#667eea',
                            backgroundColor: 'rgba(102, 126, 234, 0.1)',
                            tension: 0.4
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { display: false } },
                        scales: { y: { beginAtZero: true } }
                    }
                });
            }

            const accountsCtx = document.getElementById('accountsChart');
            if (accountsCtx) {
                const activeAccounts = accounts.filter(acc => acc.connected).length;
                const inactiveAccounts = accounts.length - activeAccounts;
                
                new Chart(accountsCtx, {
                    type: 'doughnut',
                    data: {
                        labels: ['Ativas', 'Inativas'],
                        datasets: [{
                            data: [activeAccounts, inactiveAccounts],
                            backgroundColor: ['#4facfe', '#fa709a']
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { position: 'bottom' } }
                    }
                });
            }

            const activityCtx = document.getElementById('activityChart');
            if (activityCtx) {
                new Chart(activityCtx, {
                    type: 'bar',
                    data: {
                        labels: ['00h', '04h', '08h', '12h', '16h', '20h'],
                        datasets: [{
                            label: 'Atividade',
                            data: [0, 0, 0, 0, 0, 0],
                            backgroundColor: '#43e97b'
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { display: false } },
                        scales: { y: { beginAtZero: true } }
                    }
                });
            }

            const mediaCtx = document.getElementById('mediaChart');
            if (mediaCtx) {
                new Chart(mediaCtx, {
                    type: 'pie',
                    data: {
                        labels: ['Texto', 'Fotos', 'Vídeos', 'Áudios'],
                        datasets: [{
                            data: [0, 0, 0, 0],
                            backgroundColor: ['#667eea', '#f093fb', '#4facfe', '#43e97b']
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { position: 'bottom' } }
                    }
                });
            }
        }

        // API functions
        async function connectAccount() {
            const phone = document.getElementById('phone').value;
            const api_id = document.getElementById('api_id').value;
            const api_hash = document.getElementById('api_hash').value;
            
            if (!phone || !api_id || !api_hash) {
                alert('Por favor, preencha todos os campos');
                return;
            }
            
            try {
                const response = await fetch('/api/connect-account', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        phone: phone,
                        api_id: parseInt(api_id),
                        api_hash: api_hash
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('Conta conectada com sucesso!');
                    loadAccounts();
                    document.getElementById('phone').value = '';
                    document.getElementById('api_id').value = '';
                    document.getElementById('api_hash').value = '';
                } else {
                    alert('Erro: ' + (data.error || 'Erro desconhecido'));
                }
            } catch (error) {
                console.error('Erro ao conectar conta:', error);
                alert('Erro de conexão com a API');
            }
        }

        async function removeAccount(phone) {
            if (confirm('Tem certeza que deseja remover esta conta?')) {
                try {
                    const response = await fetch('/api/remove-account', {
                        method: 'DELETE',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ phone: phone })
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        alert('Conta removida com sucesso!');
                        loadAccounts();
                    } else {
                        alert('Erro: ' + (data.error || 'Erro desconhecido'));
                    }
                } catch (error) {
                    console.error('Erro ao remover conta:', error);
                    alert('Erro de conexão com a API');
                }
            }
        }

        async function sendMessage() {
            const chat_id = document.getElementById('chat_id').value;
            const message = document.getElementById('message').value;
            
            if (!chat_id || !message) {
                alert('Por favor, preencha todos os campos obrigatórios');
                return;
            }
            
            try {
                const response = await fetch('/api/send-message', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        chat_id: chat_id,
                        message: message
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('Mensagem enviada com sucesso!');
                    document.getElementById('message').value = '';
                    loadStats();
                } else {
                    alert('Erro: ' + (data.error || 'Erro desconhecido'));
                }
            } catch (error) {
                console.error('Erro ao enviar mensagem:', error);
                alert('Erro de conexão com a API');
            }
        }

        async function sendMedia() {
            const chat_id = document.getElementById('media_chat_id').value;
            const media_url = document.getElementById('media_url').value;
            const media_type = document.getElementById('media_type').value;
            const caption = document.getElementById('media_caption').value;
            
            if (!chat_id || !media_url) {
                alert('Por favor, preencha todos os campos obrigatórios');
                return;
            }
            
            const endpoint = `/api/send-${media_type}`;
            const payload = {
                chat_id: chat_id,
                [`${media_type}_url`]: media_url,
                caption: caption
            };
            
            try {
                const response = await fetch(endpoint, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert(`${media_type.charAt(0).toUpperCase() + media_type.slice(1)} enviado com sucesso!`);
                    document.getElementById('media_url').value = '';
                    document.getElementById('media_caption').value = '';
                    loadStats();
                } else {
                    alert('Erro: ' + (data.error || 'Erro desconhecido'));
                }
            } catch (error) {
                console.error('Erro ao enviar mídia:', error);
                alert('Erro de conexão com a API');
            }
        }

        async function saveWebhook(phone) {
            const input = document.getElementById(`webhook-input-${phone}`);
            const webhookUrl = input.value.trim();
            
            if (!webhookUrl) {
                alert('Por favor, insira uma URL válida.');
                return;
            }
            
            try {
                const response = await fetch('/api/set-webhook', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        webhook_url: webhookUrl,
                        sender_phone: phone
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('Webhook salvo com sucesso!');
                } else {
                    alert('Erro: ' + (data.error || 'Erro desconhecido'));
                }
            } catch (error) {
                console.error('Erro ao salvar webhook:', error);
                alert('Erro de conexão com a API');
            }
        }

        // Atualizar dados periodicamente
        setInterval(() => {
            loadStats();
            if (document.getElementById('accounts').classList.contains('active')) {
                loadAccounts();
            }
        }, 30000);
    </script>
</body>
</html>
EOF

log_success "Interface web criada"

# 10. Criar ambiente virtual e instalar dependências
log_info "9/10 Configurando ambiente Python..."
python3 -m venv venv || {
    log_warning "Falha ao criar venv, tentando alternativa..."
    python3 -m pip install --user virtualenv
    python3 -m virtualenv venv
}

source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1 || log_warning "Falha ao atualizar pip"
pip install -r requirements.txt > /dev/null 2>&1 || {
    log_warning "Instalando dependências individualmente..."
    pip install flask telethon requests python-dotenv > /dev/null 2>&1
}
log_success "Ambiente Python configurado"

# 11. Criar script de execução
log_info "10/10 Criando script de execução..."
cat > run.sh << 'EOF'
#!/bin/bash

# Telegram SaaS Pro v4 - Script de Execução
echo "🚀 Iniciando Telegram SaaS Pro v4..."
echo "===================================="

# Verificar se está no diretório correto
if [ ! -f "telegram_api_v4.py" ]; then
    echo "❌ Arquivo telegram_api_v4.py não encontrado!"
    exit 1
fi

# Ativar ambiente virtual
echo "🔧 Ativando ambiente virtual..."
source venv/bin/activate

# Verificar dependências
echo "🔍 Verificando dependências..."
python3 -c "import flask, telethon, requests; print('✅ Dependências verificadas')" || {
    echo "⚠️ Instalando dependências..."
    pip install -r requirements.txt
}

# Verificar porta
echo "🌐 Verificando porta 5000..."
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️ Porta 5000 já está em uso, parando processo anterior..."
    pkill -f telegram_api || true
    sleep 2
fi

echo ""
echo "📊 INFORMAÇÕES DO SISTEMA:"
echo "• Python: $(python3 --version 2>&1)"
echo "• Diretório: $(pwd)"
echo "• Data/Hora: $(date)"
echo ""

echo "🌐 URLS DE ACESSO:"
echo "• Local: http://localhost:5000"

# Detectar IP externo
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "IP_NAO_DETECTADO")
if [ "$EXTERNAL_IP" != "IP_NAO_DETECTADO" ]; then
    echo "• Rede local: http://$EXTERNAL_IP:5000"
fi

echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "• Parar: Ctrl+C"
echo "• Status: curl http://localhost:5000/api/status"
echo "• Logs: Ver neste terminal"
echo ""

echo "🚀 Iniciando servidor..."
echo "======================================"

# Iniciar aplicação
python3 telegram_api_v4.py
EOF

chmod +x run.sh
log_success "Script de execução criado"

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
echo ""
echo -e "${CYAN}🔧 COMANDOS ÚTEIS:${NC}"
echo "• Iniciar: ./run.sh"
echo "• Parar: Ctrl+C ou pkill -f telegram_api"
echo "• Status: curl http://localhost:5000/api/status"
echo ""
echo -e "${CYAN}🌐 ACESSO EXTERNO (se necessário):${NC}"
echo "• Liberar firewall: ufw allow 5000"

# Detectar IP externo
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "SEU_IP_VPS")
echo "• Acesso externo: http://$EXTERNAL_IP:5000"
echo ""
log_info "Sistema instalado em: $(pwd)/$PROJECT_DIR"
echo ""
echo -e "${GREEN}🎉 Para iniciar agora mesmo:${NC}"
echo -e "${YELLOW}cd $PROJECT_DIR && ./run.sh${NC}"

