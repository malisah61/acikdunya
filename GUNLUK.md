# Geliştirme günlüğü

## 2026-11-25 (gece çalışması)
- Yeni: meslek/kariyer sistemi (`Oyun.MESLEKLER`). Hastane nöbeti artık Stajyer → Hemşire → Asistan Doktor → Uzman Doktor basamaklı (400 → 800 TL). Bakkalda "Rafları diz" mesaisi (4 saat, Çırak → Tezgâhtar → Kalfa). İş sayıları kayda yazılır.
- Yeni: Telefon menüsü (sağ alttaki "Telefon" düğmesi): saat, para, meslekler, terfiye kalan iş, ipucu. Açıkken oyun durur.
- İyileştirme (performans): 48 sokak lambasının direk ve başlıkları MultiMesh'e taşındı (~96 çizim çağrısı az); gece sadece oyuncuya en yakın 8 lambanın ışığı yanıyor, başlıklar parlıyor.
- İyileştirme (hissiyat): sakinler yanından geçince durup sana dönüp selam veriyor; acıkınca/yorulunca bir kere uyarı mesajı ve kırmızı yanıp sönen çubuk.
- Görseller: Sprite Atölye siparişi verilemedi — bu gece oturumun `sprite-atolye` deposuna erişimi yoktu ve bu depodaki `ATOLYE_TOKEN` secret'ı tanımlı değil ("Atölyeye sipariş ver" iş akışı bu yüzden hata verdi). `assets/ben/foto.png` de henüz yok.

## 2026-11-25 (gündüz, elle başlatılan tur)
- Görseller: yine sipariş verilemedi — oturumun `sprite-atolye` deposuna erişimi yok, `ATOLYE_TOKEN` hâlâ tanımlı değil. Doku siparişleri (`siparis_doku.json`, 7 doku, hepsi `"doku": true`) hazır bekliyor; `siparis.py` eki atölyeye erişim gelince yapılacak.
- Yeni: Kahvehanede garsonluk (3 saat; Çaycı Çırağı → Garson → Ocakbaşı Ustası, 110 → 200 TL).

## 2026-11-25 (gece çalışması, 2. tur) — sesler
- Yeni: `betikler/ses.gd` (autoload `Ses`). Efekt havuzu (6 düz + 6 konumlu), replik oynatıcı (kişi başına 25 sn'de bir), gündüz/gece ortam sesi (içeride kısılır, yumuşak geçiş), müzik katmanı (dosya gelince çalar), ses düzeyleri `user://ayarlar.json`'a yazılır. Dosya yoksa sessiz.
- Sesler bağlandı: zemine göre adım (asfalt/kaldırım/otopark, çim, bina içi), bina kapısı, bakkal zili, kasa (alışveriş ve maaş), simit yeme, çay kaşığı, düğme tıklaması, bildirim. Esnaf bölgesine girince selam repliği; hastaneye girince Hemşire Ayşe karşılıyor; uzun saçlı bazı sakinler "teyze" olarak sesli selam veriyor.
- Yeni: Esnafla dostluk (Tanıdık → Ahbap 5 → Dost 15): ahbapta simit 20 TL / çay 8 TL, dostta mesaide %10 bahşiş. Telefonda "Dostlar" bölümü ve ses ayarı kaydırıcıları. Kayda yazılır.
- Ses dosyaları (17, ~0,6 MB): 10 efekt + 2 ortam koddan sentez; 5 Türkçe replik Speko (gpt-4o-mini-tts). Liste: `assets/siparis_ses.json`, lisanslar: `assets/ses/LISANSLAR.md`. CC0 siteleri ağ engeline takıldı.
- Görseller: yine sipariş verilemedi — `ATOLYE_TOKEN` secret'ı tanımlı değil ve oturumun `sprite-atolye` deposuna erişimi yok. `assets/ben/foto.png` yok.

## 2026-11-25 (gece çalışması, 3. tur)
- Yeni: **Günlük görevler** (`Oyun.GOREV_HAVUZU`): her gün 3 görev, ödüllü; hepsi bitince +50 TL. Telefonda "Bugünün görevleri" (yazı kaydırılabilir oldu). Kayda yazılır.
- Yeni: **Yan görev — teyzenin ekmeği** ve **mahalle itibarı** (Yeni gelen → Mahallenin gözdesi).
- İyileştirme: sakinlerin tipi var (teyze, kadın, öğrenci, memur, işçi) — her biri kendi cümlesi ve sesiyle selam verir. Mesaj süresi satır sayısına göre uzuyor.
- Sesler (14 yeni): Speko ile 7 replik (öğrenci, memur, işçi, kadın selamı; Hasan ve Rıza teşekkürü; Dr. Selin terfi tebriği); koddan sentez (`araclar/ses_sentez.py`): kahvehane ve hastane iç ortamı, mahalle ve gece müziği, uyku, görev tamam, terfi fanfarı. İç mekâna girince o binanın ortam sesi açılıyor, müzik kısılıyor. Ezan: sentezle saygılı olmayacağı için atlandı.
- Atölye: `siparis/siparis.py`'ye `"doku": true` → `tileable=true, auto=false` eki gönderildi. Bu oturumun atölyeye erişimi var; karakter ve ikon siparişi verildi.
- Görseller (Sprite Atölye, 3 tur): 9 karakter görünümü seçildi (`assets/uretilen/karakterler/`: bakkal Hasan, kahveci Rıza, Dr. Selin, hemşire Ayşe, teyze, öğrenci, memur, işçi, kadın), ikonlar: çay, nöbet, yatak, simit, raf (bakkal mesaisi), tepsi (garsonluk), telefon. Hemşire (anime çıkmıştı), kadın (iki kişi) ve simit (çörek gibi) tarifleri düzeltilip 2. turda yenilendi. Ekmek ikonu kötü çıktı, tarifi düzeltildi.
- Dokular (ilk kez, dikişsiz): asfalt, çimen, kaldırım, parke, sıva, yaprak — 512 px. Çatı beyaz lekeli çıktı, tarifi düzeltildi; şimdilik düz renk.
- `assets/ben/foto.png` hâlâ yok: `kisi_oyuncu` ve `oyuncu_portre` atlandı.
