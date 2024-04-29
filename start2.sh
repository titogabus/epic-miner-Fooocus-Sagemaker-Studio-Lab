#!/bin/bash

if [ ! -d "DeFooocus" ]; then
  git clone https://github.com/ehristoforu/DeFooocus.git
fi

cd DeFooocus
git pull

if [ ! -L ~/.conda/envs/defooocus ]; then
    ln -s /tmp/defooocus ~/.conda/envs/
fi

eval "$(conda shell.bash hook)"

if [ ! -d /tmp/defooocus ]; then
    mkdir /tmp/defooocus
    conda env create -f environment.yaml
    conda activate defooocus
    pip install -r requirements_versions.txt
    pip install torch torchvision --force-reinstall --index-url https://download.pytorch.org/whl/cu117
    conda install glib -y
    rm -rf ~/.cache/pip
fi

# Setup the path for model checkpoints
current_folder=$(pwd)
model_folder=${current_folder}/models/checkpoints-real-folder
if [ ! -e config.txt ]; then
  json_data="{ \"path_checkpoints\": \"$model_folder\" }"
  echo "$json_data" > config.txt
  echo "JSON file created: config.txt"
else
  echo "Updating config.txt to use checkpoints-real-folder"
  jq --arg new_value "$model_folder" '.path_checkpoints = $new_value' config.txt > config_tmp.txt && mv config_tmp.txt config.txt
fi

# If the checkpoints folder exists, move it to the new checkpoints-real-folder
if [ ! -L models/checkpoints ]; then
    mv models/checkpoints models/checkpoints-real-folder
    ln -s models/checkpoints-real-folder models/checkpoints
fi

# Activate the fooocus environment
conda activate defooocus
cd ..

# Run Python script in the background
python DeFooocus/entry_with_update.py --always-high-vram &

sleep 120

# Run cloudflared tunnel
cloudflared tunnel --url localhost:7865

# Check if the script was called with the "reset" argument
if [ $# -eq 0 ]; then
  sh cloudflare.sh
elif [ $1 = "reset" ]; then
  sh cloudflare.sh
fi
