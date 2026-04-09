# FFmpeg Mosaic Service

Servizio che legge fino a 4 stream HLS e li compone in un mosaico dinamico, servito come nuovo stream HLS. Il layout si adatta automaticamente al numero di stream attivi.

## Descrizione

Il servizio controlla periodicamente quali stream sono online e costruisce il layout di conseguenza:

| Stream attivi | Layout |
|---|---|
| 4 | Mosaico 2x2 completo |
| 3 | Mosaico 2x2 con nero in basso a destra |
| 2 | Affiancati 50/50 |
| 1 | Fullscreen |
| 0 | Schermata nera "Nessun segnale" |

## Come deployare su Railway

1. Crea un nuovo servizio su [Railway](https://railway.app) partendo da questo repository.
2. Seleziona la cartella `mosaic/` come contesto Docker.
3. Imposta la porta esposta su `8080`.
4. Configura le variabili d'ambiente (vedi sezione sotto).
5. Fai il deploy e attendi che il servizio si avvii.

## URL dello stream output

```
https://<dominio>/live/mosaic/index.m3u8
```

## Variabili d'ambiente

### Stream (tutte opzionali)

| Variabile | Descrizione |
|---|---|
| `STREAM_1` | URL stream HLS pc1 (in alto a sinistra) |
| `STREAM_2` | URL stream HLS pc2 (in alto a destra) |
| `STREAM_3` | URL stream HLS pc3 (in basso a sinistra) |
| `STREAM_4` | URL stream HLS pc4 (in basso a destra) |

### Tecniche (tutte obbligatorie)

| Variabile | Descrizione |
|---|---|
| `OUTPUT_FPS` | FPS output (es. `60`) |
| `OUTPUT_WIDTH` | Larghezza output in pixel (es. `1280`) |
| `OUTPUT_HEIGHT` | Altezza output in pixel (es. `720`) |
| `HLS_TIME` | Durata segmenti HLS in secondi (es. `2`) |
| `HLS_LIST_SIZE` | Numero segmenti nel playlist (es. `6`) |
| `PRESET` | Preset x264: `ultrafast`, `veryfast`, `fast` (es. `veryfast`) |

## Note sulle risorse CPU

La codifica video in tempo reale è **computazionalmente intensa**. Si consiglia almeno:

- **2 vCPU** dedicate
- **1 GB RAM**

In ambienti con risorse limitate usa `PRESET=ultrafast` e/o riduci `OUTPUT_FPS` a `30`.