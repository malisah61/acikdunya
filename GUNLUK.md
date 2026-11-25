# Geliştirme günlüğü

## 2026-11-25 (gece çalışması)
- Yeni: meslek/kariyer sistemi (`Oyun.MESLEKLER`). Hastane nöbeti artık Stajyer → Hemşire → Asistan Doktor → Uzman Doktor basamaklı (400 → 800 TL). Bakkalda "Rafları diz" mesaisi (4 saat, Çırak → Tezgâhtar → Kalfa). İş sayıları kayda yazılır.
- Yeni: Telefon menüsü (sağ alttaki "Telefon" düğmesi): saat, para, meslekler, terfiye kalan iş, ipucu. Açıkken oyun durur.
- İyileştirme (performans): 48 sokak lambasının direk ve başlıkları MultiMesh'e taşındı (~96 çizim çağrısı az); gece sadece oyuncuya en yakın 8 lambanın ışığı yanıyor, başlıklar parlıyor.
- İyileştirme (hissiyat): sakinler yanından geçince durup sana dönüp selam veriyor; acıkınca/yorulunca bir kere uyarı mesajı ve kırmızı yanıp sönen çubuk.
- Görseller: Sprite Atölye siparişi verilemedi — bu gece oturumun `sprite-atolye` deposuna erişimi yoktu ve bu depodaki `ATOLYE_TOKEN` secret'ı tanımlı değil ("Atölyeye sipariş ver" iş akışı bu yüzden hata verdi). `assets/ben/foto.png` de henüz yok.
