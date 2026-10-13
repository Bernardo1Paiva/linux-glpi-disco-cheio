#!/bin/bash
# Apaga backups SQL antigos do GLPI para o disco não lotar de novo.
# Mantém os arquivos dos últimos DIAS dias e registra o que foi apagado.

DIR="/caminho/dos/backups/glpi"   # pasta onde ficam os dumps .sql
DIAS=30                           # quantos dias de backup manter
LOG="/var/log/limpar-backups.log"

if [ ! -d "$DIR" ]; then
    echo "$(date '+%F %T') pasta $DIR não encontrada" >> "$LOG"
    exit 1
fi

# Lista e apaga os .sql com mais de $DIAS dias
find "$DIR" -type f -name "*.sql" -mtime +"$DIAS" -print -delete >> "$LOG" 2>&1

echo "$(date '+%F %T') limpeza concluída, uso do disco: $(df -h / | awk 'NR==2 {print $5}')" >> "$LOG"
