#!/usr/bin/env bash

set -x
set -e

DIR="$( cd "$( dirname "$0" )" && cd .. && pwd )"
echo "working directory: ${DIR}"

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="${DIR}/checkpoint/biencoder_bge_large_$(date +%F-%H%M.%S)"
fi
if [ -z "$DATA_DIR" ]; then
  DATA_DIR="${DIR}/data/finance6w"
fi

mkdir -p "${OUTPUT_DIR}"

PROC_PER_NODE=$(nvidia-smi --list-gpus | wc -l)
# python -u -m torch.distributed.launch --nproc_per_node ${PROC_PER_NODE} src/train_biencoder.py \
# --per_device_train_batch_size 16 \
# --model_name_or_path intfloat/simlm-base-msmarco \
# bge-large-zh-v1.5
deepspeed --include localhost:0,1,2,3 src/train_biencoder.py --deepspeed ds_config.json \
    --model_name_or_path /home/tju_by/hcz/retrieval_model_train/model/bge-large-zh-v1.5 \
    --per_device_train_batch_size 6 \
    --per_device_eval_batch_size 32 \
    --add_pooler False \
    --t 0.02 \
    --seed 1234 \
    --do_train \
    --fp16 \
    --train_file "${DATA_DIR}/train.jsonl" \
    --validation_file "${DATA_DIR}/dev.jsonl" \
    --q_max_len 32 \
    --p_max_len 144 \
    --train_n_passages 16 \
    --dataloader_num_workers 1 \
    --num_train_epochs 3 \
    --learning_rate 2e-5 \
    --use_scaled_loss True \
    --warmup_steps 1000 \
    --share_encoder True \
    --logging_steps 50 \
    --output_dir "${OUTPUT_DIR}" \
    --data_dir "${DATA_DIR}" \
    --save_total_limit 2 \
    --save_strategy epoch \
    --evaluation_strategy epoch \
    --remove_unused_columns False \
    --overwrite_output_dir \
    --disable_tqdm True \
    --report_to none "$@"
#  --max_train_samples 24000 \