# FFmpeg Mosaic Service

Servizio che legge 3 stream HLS e li compone in un mosaico 2x2 a 60fps in risoluzione 1280x720, servito come nuovo stream HLS.

## Descrizione

Il servizio combina 3 sorgenti video live in un unico mosaico 2x2:

- **PC1** — in alto a sinistra
- **PC2** — in alto a destra
- **PC3** — in basso a sinistra
- **Nero** — in basso a destra (placeholder)

Output: stream HLS 1280x720 @ 60fps con codec H.264.

## Come deployare su Railway

1. Crea un nuovo servizio su [Railway](https://railway.app) partendo da questo repository.
2. Seleziona la cartella `mosaic/` come contesto Docker (o configura il `Dockerfile` nel servizio).
3. Imposta la porta esposta su `8080`.
4. Fai il deploy e attendi che il servizio si avvii.

## URL dello stream output

Una volta avviato il servizio, lo stream HLS è disponibile all'indirizzo:

```
http://<dominio>/live/mosaic/index.m3u8
```

Sostituisci `<dominio>` con il dominio assegnato da Railway al tuo servizio.

## Variabili d'ambiente

Nessuna variabile d'ambiente è obbligatoria per il funzionamento base del servizio.

| Variabile | Default | Descrizione |
|-----------|---------|-------------|
| *(nessuna per ora)* | — | — |

## Note sulle risorse CPU

La codifica video in tempo reale di un mosaico 4-input a 60fps è **computazionalmente intensa**. Si consiglia almeno:

- **2 vCPU** dedicate
- **512 MB RAM** minimi (consigliato 1 GB)

In ambienti con risorse limitate, considera di ridurre il framerate a 30fps modificando il parametro `-r 60` e `fps=60` in `mosaic.sh`.
