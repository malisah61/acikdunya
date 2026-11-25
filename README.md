# Açık Dünya

Gerçek hayat RPG'si: tepeden bakan 3D kamera (GTA 1-2 havası), açık dünya mahalle, kendi karakterin.
Godot 4.3 + GDScript, GL Compatibility (eski telefonlarda da çalışsın diye).

## İndir (her gönderimde otomatik derlenir)
- Android: https://github.com/malisah61/acikdunya/releases/download/son-surum/acikdunya.apk
- Windows: https://github.com/malisah61/acikdunya/releases/download/son-surum/acikdunya.exe
- Linux: https://github.com/malisah61/acikdunya/releases/download/son-surum/acikdunya.x86_64

## Şu an oyunda (v0.1 — ilk mahalle)
- Karakter oluşturma ("Kendini oyuna ekle"): isim, ten, saç rengi/modeli, sakal, gömlek, pantolon
- Mahalle: 3×3 yol ağı, kaldırımlar, sokak lambaları, park + havuz, otopark, apartmanlar
- İçine girilen binalar (girince çatı ve ön duvar kalkar): **Ev** (uyu), **Bakkal** (simit + ayran, raf dizme mesaisi), **Kahvehane** (çay, garsonluk), **Hastane** (8 saatlik nöbet → para)
- Meslekler ve kariyer basamakları: Hastane (Stajyer → Hemşire → Asistan Doktor → Uzman Doktor), Bakkal (Çırak → Tezgâhtar → Kalfa), Kahvehane (Çaycı Çırağı → Garson → Ocakbaşı Ustası); çalıştıkça terfi, terfiyle daha yüksek ücret
- **Telefon** menüsü: saat, para, meslekler, terfiye kalan iş sayısı, duruma göre ipucu
- Mahalle sakinleri yanından geçince durup selam verir ("Günaydın!", "Kolay gelsin!"…)
- Acıkınca / yorulunca uyarı mesajı ve yanıp sönen kırmızı çubuk
- Gece-gündüz döngüsü (24 dakikada bir gün): gün batımı, lambalar ve pencereler gece yanar
- Tokluk / enerji / para; enerji biterse bayılırsın
- Gündüz dolaşıp gece evine dönen 24 mahalle sakini
- **Esnafla dostluk**: Bakkal Hasan, Kahveci Rıza ve Dr. Selin'le her alışveriş/mesai dostluğu artırır (Tanıdık → Ahbap → Dost); ahbap olunca simit/çay indirimli, dost olunca mesaide %10 bahşiş. Telefonda "Dostlar" bölümü
- **Sesler**: zemine göre adım (asfalt/çim/ev içi), kapı, bakkal zili, kasa, yeme, çay kaşığı, arayüz tıklama, bildirim; gündüz/gece mahalle ortam sesi (içeride kısılır, yumuşak geçiş); esnaf ve teyzelerin sesli selamı; telefonda efekt ve ortam/müzik ses ayarı
- Otomatik kayıt (dakikada bir, uyuyunca, nöbet bitince)

## Kontroller
- PC: WASD / oklar yürü, Shift koş, E eylem, fare tekerleği yakınlaş
- Telefon: sol alt joystick (sonuna kadar itince koşar), sağ alt eylem ve +/− düğmeleri

## Sprite Atölye bağlantısı
Oyunun görselleri [Sprite Atölye](https://github.com/malisah61/sprite-atolye)'den gelir. Oyun, `assets/uretilen/` altında bulduğu her görseli kendiliğinden kullanır, yoksa düz renklerle çalışır.

| Dosya | Ne | Oyunda nerede |
|---|---|---|
| `assets/siparis.json` | portre, ikonlar ve 10 karakterin boydan görünümü (`kisi_*`) | sol üst panel, eylem düğmesi, esnafla konuşunca kişi kartı |
| `assets/siparis_ses.json` | oyunun ses listesi (efekt, ortam, müzik, replik) → `assets/ses/<tur>/<ad>.ogg` | `betikler/ses.gd` (autoload `Ses`), dosya yoksa sessiz |
| `assets/siparis_doku.json` | dikişsiz dokular (çimen, asfalt, kaldırım, sıva, parke, çatı, yaprak) | tüm dünya |

Sipariş vermek için: bu depoda Actions → **Atölyeye sipariş ver** (ya da `assets/siparis.json` değişince kendiliğinden başlar).

**Atölye tokenı (bir kere):** GitHub → Settings → Developer settings → Fine-grained tokens → Generate new token →
Repository access: yalnız `malisah61/sprite-atolye` → Permissions: **Actions: Read and write** → oluştur.
Sonra bu depoda Settings → Secrets and variables → Actions → New repository secret: ad `ATOLYE_TOKEN`, değer token.

**Karakterler:** `kisi_*` siparişleri önden, T-pozda, boydan çizim üretir (`assets/uretilen/karakterler/`). Bunlar şimdi kişi kartında görünür; sonraki adımda atölyenin 3D hattıyla (görsel → 3D → iskelet) oyundaki modellere dönüşecek. Sadece karakterler için: `sadece` alanına `kisi_oyuncu,kisi_bakkal_hasan,...` yaz.

**Kendi yüzün:** `assets/ben/foto.png` olarak önden net bir fotoğraf yükle, sonra siparişi `sadece: oyuncu_portre` ile çalıştır. Fotoğraf oyun paketine girmez.

## Telefon performansı notları
- Çok tekrar eden nesneler (pencereler, kapılar, şerit çizgileri, lamba direkleri ve başlıkları) `Dunya.toplu` / `toplu_mesh` ile tek çizimde.
- Ses: en fazla 6 düz + 6 konumlu efekt ve 1 replik aynı anda; ortam sesleri kısıkken durdurulur. Toplam ses boyutu ≤ 25 MB.
- Gece yalnız oyuncuya en yakın 8 sokak lambası gerçek ışık yayar; diğerlerinin başlığı sadece parlar.

## Yol haritası
1. Atölyeden 3D karakter (görsel → 3D → iskelet) ve fotoğraftan sana benzeyen oyuncu modeli
2. Yeni bölgeler (çarşı, sahil, sanayi) ve parça parça yüklenen büyük harita
3. Meslekler ve mini oyunlar (acil nöbeti, taksi, esnaflık), kariyer basamakları
   - [x] Kariyer basamakları (hastane, bakkal) ve bakkalda mesai
   - [x] Kahvehanede garsonluk
   - [ ] Taksi şoförlüğü
   - [ ] İş başında küçük mini oyunlar (acil nöbetinde hasta sırası, rafları doğru dizme)
4. Ev kiralama/satın alma, eşyalar, araba kullanma
5. Komşularla ilişki, yan görevler, telefon menüsü
   - [x] Telefon menüsü (temel: durum, meslekler, ipucu) ve sakinlerin selamlaşması
   - [x] Esnafla dostluk puanı (indirim, bahşiş)
   - [ ] Sakinlerle dostluk, yan görevler (telefondan)
6. Hava durumu, mevsimler, sesler
   - [x] Ses yöneticisi, efektler, zemine göre adım, gündüz/gece ortam, NPC replikleri, ses ayarı
   - [ ] Kahvehane ve hastane iç ortam sesi, uzaktan kısa ezan, mahalle ve gece müziği (`siparis_ses.json`'da bekliyor)
   - [ ] Sprite Atölye ses sekmesinden üretim (hazır olunca sentez seslerin yerine)
   - [ ] Daha çok replik (öğrenci, memur, işçi; terfi/teşekkür tepkileri)
   - [ ] Yağmur, rüzgâr; mevsimler
