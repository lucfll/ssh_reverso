#https://chatgpt.com/c/67732298-80f4-8003-b591-223716a1c49d
#https://chatgpt.com/c/6772f78a-5638-8003-8b3d-22615441904b
#!/bin/bash

# Atualiza os pacotes disponíveis
sudo apt update

# Instala o servidor OpenSSH
sudo apt install -y openssh-server

# Gera uma chave SSH RSA de 4096 bits, com o nome personalizado e comentário
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_reverse -C "reverse_ssh" -N ""

# Solicita o IP da máquina remota
read -p "Digite o IP da máquina remota: " remote_ip

# Copia a chave pública para a máquina remota
ssh-copy-id -i ~/.ssh/id_rsa_reverse.pub root@$remote_ip

echo "Chave SSH pública transferida com sucesso para $remote_ip!"

# Testa a conexão SSH com a chave privada gerada
echo "Testando a conexão SSH..."
ssh -i ~/.ssh/id_rsa_reverse root@$remote_ip "echo 'Conexão SSH bem-sucedida!'"

# Permitir redirecionamento de portas na máquina remota
echo "Habilitando redirecionamento de portas na máquina remota..."

# Edita o arquivo sshd_config na máquina remota para permitir redirecionamento de portas
ssh -i ~/.ssh/id_rsa_reverse root@$remote_ip "sed -i '/^#AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config"
ssh -i ~/.ssh/id_rsa_reverse root@$remote_ip "sed -i '/^#GatewayPorts/c\GatewayPorts yes' /etc/ssh/sshd_config"

# Reinicia o serviço SSH na máquina remota
ssh -i ~/.ssh/id_rsa_reverse root@$remote_ip "sudo systemctl restart ssh"

echo "Configuração SSH atualizada e serviço reiniciado na máquina remota!"

# Solicita as informações para o redirecionamento de porta reverso
read -p "Digite o IP do host remoto: " remote_host_ip
read -p "Digite a porta a ser ouvida no host remoto (ex: 8888): " remote_port
read -p "Digite a porta local que será redirecionada (ex: 8080): " local_port

# Salva essas informações em um arquivo de configuração
echo "remote_host_ip=$remote_host_ip" > ~/.reverse_ssh_config
echo "remote_port=$remote_port" >> ~/.reverse_ssh_config
echo "local_port=$local_port" >> ~/.reverse_ssh_config

echo "Informações para o Reverse SSH Tunnel salvas com sucesso!"

# Definir o arquivo do serviço systemd
SERVICE_FILE="/etc/systemd/system/ssh_reverse_tunnel.service"

# Definir o conteúdo do arquivo de serviço
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=SSH Reverse Tunnel
After=network.target

[Service]
ExecStart=/usr/bin/ssh -R 0.0.0.0:$remote_port:localhost:$local_port -i /root/.ssh/id_rsa_reverse -N root@$remote_host_ip
Restart=always
RestartSec=10
StartLimitIntervalSec=0
User=root
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOF

# Carregar as novas configurações do systemd
sudo systemctl daemon-reload

# Habilitar o serviço para iniciar automaticamente após o boot
sudo systemctl enable ssh_reverse_tunnel.service

# Iniciar o serviço imediatamente
sudo systemctl start ssh_reverse_tunnel.service

# Verificar o status do serviço
sudo systemctl status ssh_reverse_tunnel.service

# Exibir mensagem de instrução final
echo -e "\nConfiguração concluída com sucesso! Agora, para personalizar as portas utilizadas pelo túnel SSH reverso,"
echo -e "favor alterar as portas configuradas no arquivo de serviço: /etc/systemd/system/ssh_reverse_tunnel.service."
echo -e "Certifique-se de ajustar as portas conforme necessário para o seu ambiente, para garantir a funcionalidade e segurança adequadas.\n"
