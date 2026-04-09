# FFmpeg Mosaic Service

Servizio che legge 3 stream HLS e li compone in un mosaico 2x2 a 60fps in risoluzione 1280x720, servito come nuovo stream HLS.

## Descrizione

Il servizio combina 3 sorgenti video live in un unico mosaico 2x2:

- **STREAM_1** — in alto a sinistra
- **STREAM_2** — in alto a destra
- **STREAM_3** — in basso a sinistra
- **Nero** — in basso a destra (placeholder)

Output: stream HLS configurabile tramite variabili d'ambiente.

## Come deployare su Railway

1. Crea un nuovo servizio su [Railway](https://railway.app) partendo da questo repository.
2. Seleziona la cartella `mosaic/` come contesto Docker (o configura il `Dockerfile` nel servizio).
3. Imposta la porta esposta su `8080`.
4. Configura tutte le variabili d'ambiente obbligatorie (vedi sezione sotto).
5. Fai il deploy e attendi che il servizio si avvii.

## URL dello stream output

Una volta avviato il servizio, lo stream HLS è disponibile all'indirizzo:

```
http://<dominio>/live/mosaic/index.m3u8
```

Sostituisci `<dominio>` con il dominio assegnato da Railway al tuo servizio.

## Variabili d'ambiente

Tutte le variabili sono **obbligatorie**. Il container non si avvia se una manca.

| Variabile | Descrizione |
|-----------|-------------|
| `STREAM_1` | URL dello stream HLS sorgente 1 (in alto a sinistra) |
| `STREAM_2` | URL dello stream HLS sorgente 2 (in alto a destra) |
| `STREAM_3` | URL dello stream HLS sorgente 3 (in basso a sinistra) |
| `OUTPUT_FPS` | FPS dell'output (es. `60`) |
| `OUTPUT_WIDTH` | Larghezza output in pixel (es. `1280`) |
| `OUTPUT_HEIGHT` | Altezza output in pixel (es. `720`) |
| `HLS_TIME` | Durata segmenti HLS in secondi (es. `2`) |
| `HLS_LIST_SIZE` | Numero di segmenti nel playlist (es. `6`) |
| `PRESET` | Preset x264: `ultrafast`, `veryfast`, `fast`, `medium` (es. `veryfast`) |

## Note sulle risorse CPU

La codifica video in tempo reale di un mosaico 4-input è **computazionalmente intensa**. Si consiglia almeno:

- **2 vCPU** dedicate
- **512 MB RAM** minimi (consigliato 1 GB)

In ambienti con risorse limitate, considera di usare `PRESET=ultrafast` e ridurre `OUTPUT_FPS` a `30`.