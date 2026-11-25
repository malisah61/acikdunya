# Ses dosyalarının kaynakları ve lisansları

| Dosyalar | Kaynak | Lisans |
|---|---|---|
| `efekt/*.ogg` (adım ×3, kapı, bakkal zili, kasa/para, yeme, çay kaşığı, tıklama, bildirim) | Bu depoda koddan sentezlendi (python/numpy + ffmpeg), 25 Kasım 2026 | Projeye ait, serbest kullanım |
| `ortam/mahalle_gunduz.ogg`, `ortam/gece.ogg` | Koddan sentezlendi (kuş cıvıltısı, uzak uğultu, cırcır böceği, uzak köpek); dikişsiz döngü | Projeye ait, serbest kullanım |
| `efekt/uyuma.ogg`, `efekt/gorev_tamam.ogg`, `efekt/terfi.ogg`, `ortam/kahvehane.ogg`, `ortam/hastane.ogg`, `muzik/mahalle.ogg`, `muzik/gece.ogg` | Koddan sentezlendi: `araclar/ses_sentez.py` (Karplus-Strong telli çalgı, Uşşak havası; tavla zarı, bardak şıngırtısı, monitör bipi), 25 Kasım 2026 gecesi | Projeye ait, serbest kullanım |
| `replik/*.ogg` (Bakkal Hasan, Kahveci Rıza, Dr. Selin, Hemşire Ayşe, Teyze; 25 Kasım gecesi: öğrenci, memur, işçi, kadın selamı, Hasan/Rıza teşekkür, Dr. Selin terfi tebriği — sesler ash, verse, alloy, coral, onyx, echo, nova) | Speko `audio_synthesize` — OpenAI `gpt-4o-mini-tts` (sesler: onyx, echo, nova, shimmer, fable) | Yapay zekâ ile üretilmiş ses (OpenAI kullanım şartlarına tabi) |

Sprite Atölye'nin ses sekmesi (metinden sese efekt) hazır olunca `assets/siparis_ses.json` oradan sipariş edilecek ve sentez sesler daha iyileriyle değiştirilecek.
CC0 paketler (Kenney.nl, OpenGameArt) bu oturumda ağ engeline takıldı.
