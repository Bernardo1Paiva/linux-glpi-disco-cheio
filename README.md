# Caso real: servidor do GLPI parado com o disco em 100%

Relato técnico de um incidente que resolvi como Técnico de TI: o servidor **Ubuntu** que hospeda o **GLPI** (sistema de chamados e inventário) parou de funcionar porque o disco lotou.

## Sintoma

A interface web do GLPI travava e mostrava o erro *"A ação que você requisitou não é permitida"*. Ninguém conseguia abrir ou atualizar chamados.

## Diagnóstico

Acesso ao servidor por SSH, a partir do próprio Windows:

```bash
ssh usuario@ip-do-servidor
```

**1. Ver o uso dos discos.** A partição principal (`/`) estava com 100% de uso.

```bash
df -h
```

**2. Descartar memória e processos.** A RAM e a CPU estavam normais, então o problema não era falta de memória.

```bash
free -h
top
```

**3. Descobrir quem ocupava o disco.** Fui descendo pelas pastas, sempre ordenando da maior para a menor:

```bash
sudo du -h --max-depth=1 / | sort -hr | head -n 15
```

O resultado mostrou **centenas de gigabytes de backups SQL do banco do GLPI, acumulados desde 2023**, sem nenhuma regra que apagasse os antigos.

## Solução

**1. Liberar espaço com segurança**, sem tocar no banco em uso:

```bash
sudo journalctl --vacuum-time=1s          # logs do sistema
sudo apt-get clean && sudo apt-get autoremove
sudo rm /caminho/dos/backups/*2023*.sql   # backups antigos, já conferidos
```

**2. Impedir que volte a acontecer.** Um script apaga os backups com mais de 30 dias: [`scripts/limpar-backups.sh`](scripts/limpar-backups.sh). Ele roda todo dia pelo Cron:

```bash
sudo crontab -e
```

```
0 3 * * * /usr/local/bin/limpar-backups.sh > /dev/null 2>&1
```

**3. Conferir se o Cron rodou** de verdade, lendo o log do sistema:

```bash
grep -i cron /var/log/syslog
```

Um detalhe que travou o agendamento no início: no Ubuntu, o arquivo do crontab precisa terminar com uma **linha em branco**, senão a última tarefa é ignorada.

## Resultado

- Disco voltou para um uso normal e o GLPI voltou a funcionar.
- A limpeza passou a ser automática, com registro em `/var/log/limpar-backups.log`.

## O que aprendi

- **Diagnosticar antes de apagar:** `df` mostra *se* o disco está cheio, e `du` mostra *onde*.
- **Backup sem retenção vira problema:** toda rotina de backup precisa de uma regra que diga quantos dias guardar.
- **Automatizar e verificar:** agendar no Cron não basta. É preciso ler o log para ter certeza de que rodou.

## Comandos usados

| Comando | Para quê |
| --- | --- |
| `ssh` | Acesso remoto ao servidor |
| `df -h` | Uso de cada disco |
| `du -h --max-depth=1` | Tamanho de cada pasta |
| `free -h`, `top`, `ps` | Memória e processos |
| `journalctl --vacuum-time` | Limpar logs do sistema |
| `find -mtime` | Achar arquivos por idade |
| `crontab -e` | Agendar tarefas |
| `grep /var/log/syslog` | Conferir se o Cron rodou |

## Autor

**Bernardo Ghenov Paiva**, Técnico de TI · [LinkedIn](https://www.linkedin.com/in/bernardo-ghenov-paiva-0b834b284)
