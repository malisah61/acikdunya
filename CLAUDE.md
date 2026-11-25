# Açık Dünya — çalışma kuralları

- Kullanıcı (Mehmet Ali) ile her zaman **Türkçe** konuş; raporlar Türkçe.
- Motor: Godot 4.3 + GDScript, `gl_compatibility`. Sahne neredeyse tamamen koddan kurulur (`betikler/`).
- Kamera tepeden eğik bakar (55°); binaların kapıları +Z (güney, kameraya doğru) yönüne bakar.
  İç mekâna girince `ic_mekan.gd` çatıyı ve ön duvarı gizler.
- Çarpışma katmanları: dünya = 1, oyuncu = 2; bölgeler (Area3D) yalnız 2'yi dinler.
- Görseller Sprite Atölye'den: `assets/siparis*.json` → atölyenin **Sipariş** iş akışı → `assets/uretilen/`.
  Kod, görsel yoksa düz renge düşmeli (hiçbir görsel zorunlu değil).
- `assets/ben/` kullanıcının kişisel fotoğrafı içindir; pakete girmez (export_presets dışlıyor), başka yere kopyalanmaz.
- Paket boyutu: APK ≤ 150 MB; çok tekrar eden nesneler `Dunya.toplu` (MultiMesh) ile çizilir.
- Her gönderim `Derle` iş akışını çalıştırır; duman testi betik hatasında derlemeyi durdurur.
  Gönderdikten sonra `gh run list -L 1` ile sonucu kontrol et.
