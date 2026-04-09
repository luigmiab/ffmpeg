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

Una volta avviato il servizio, lo stream HLS è disponibile all'indirizzo:

```
https://<dominio>/live/mosaic/index.m3u8
```

Sostituisci `<dominio>` con il dominio assegnato da Railway al tuo servizio.

## Variabili d'ambiente

### Variabili tecniche — obbligatorie

| Variabile | Descrizione |
|-----------|-------------|
| `OUTPUT_FPS` | FPS dell'output (es. `30`) |
| `OUTPUT_WIDTH` | Larghezza output in pixel (es. `1280`) |
| `OUTPUT_HEIGHT` | Altezza output in pixel (es. `720`) |
| `HLS_TIME` | Durata segmenti HLS in secondi (es. `2`) |
| `HLS_LIST_SIZE` | Numero di segmenti nel playlist (es. `6`) |
| `PRESET` | Preset x264: `ultrafast`, `veryfast`, `fast`, `medium` (es. `veryfast`) |

### Variabili stream — tutte opzionali

| Variabile | Descrizione |
|-----------|-------------|
| `STREAM_1` | URL dello stream HLS sorgente 1 |
| `STREAM_2` | URL dello stream HLS sorgente 2 |
| `STREAM_3` | URL dello stream HLS sorgente 3 |
| `STREAM_4` | URL dello stream HLS sorgente 4 |

## Note sulle risorse CPU

La codifica video in tempo reale di un mosaico 4-input è **computazionalmente intensa**. Si consiglia almeno:

- **2 vCPU** dedicate
- **512 MB RAM** minimi (consigliato 1 GB)

In ambienti con risorse limitate, considera di usare `PRESET=ultrafast` e ridurre `OUTPUT_FPS` a `30`.