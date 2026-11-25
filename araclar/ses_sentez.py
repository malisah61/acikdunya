"""Açık Dünya — koddan ses sentezi (atölyenin ses sekmesi hazır olana kadar).
Kullanım: python3 araclar/ses_sentez.py <çıkış_klasörü>   → <ad>.wav dosyaları (sonra ffmpeg ile .ogg)
Döngüler dikişsiz: her katman döngü uzunluğuna tam bölünür ya da son kısım başa çapraz bindirilir.
"""
import sys
import os
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(1125)


def kaydet(ad, x, kanal=1):
    x = np.asarray(x, dtype=np.float64)
    tepe = np.max(np.abs(x)) or 1.0
    x = x / tepe * 0.89
    if kanal == 2 and x.ndim == 1:
        x = np.stack([x, x], 1)
    v = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(CIKIS, ad + ".wav"), "wb") as w:
        w.setnchannels(kanal)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(v.tobytes())


def dongu(x, bindir=1.5):
    """Son `bindir` saniyeyi başa yumuşakça bindirir → dikişsiz döngü (çıktı kısalır)."""
    n = int(bindir * SR)
    bas, son = x[:n].copy(), x[-n:]
    f = np.linspace(0, 1, n)
    if x.ndim == 2:
        f = f[:, None]
    bas = bas * f + son * (1 - f)
    return np.concatenate([bas, x[n:-n]])


def zarf(n, atak=0.005, sonum=0.3):
    t = np.arange(n) / SR
    return np.minimum(t / max(atak, 1e-4), 1.0) * np.exp(-t / sonum)


def suzgec(x, alcak=None, yuksek=None):
    """FFT ile basit bant süzgeci."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if alcak:
        m *= 1 / (1 + (f / alcak) ** 4)
    if yuksek:
        m *= 1 / (1 + (yuksek / np.maximum(f, 1)) ** 4)
    return np.fft.irfft(X * m, len(x))


def ekle(hedef, ses, bas):
    bas = int(bas) % len(hedef)
    son = min(len(hedef), bas + len(ses))
    hedef[bas:son] += ses[: son - bas]
    kalan = len(ses) - (son - bas)
    if kalan > 0:  # döngü sonundan taşan kısım başa (dikişsiz)
        hedef[:kalan] += ses[son - bas:]


def tok(frek, sure, sonum, parlak=3):
    """Kısa vurmalı ton (zar, bardak, kaşık)."""
    n = int(sure * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * frek * (k * 1.51 + 1) * t) / (k + 1) for k in range(parlak))
    return s * zarf(n, 0.001, sonum)


def kahvehane(sure=30):
    n = sure * SR
    # sohbet uğultusu: konuşma bandında genlik oynayan gürültü, birkaç "masa"
    x = np.zeros(n)
    for masa in range(5):
        g = suzgec(rng.standard_normal(n), alcak=900 + masa * 150, yuksek=180)
        hece = suzgec(rng.standard_normal(n), alcak=5)  # yavaş genlik oynaması (hece ritmi)
        hece = np.clip(hece / (np.std(hece) + 1e-9), 0, None)
        x += g * hece * (0.5 + 0.2 * masa)
    x *= 0.35
    # tavla zarları: atış = 2-3 hızlı tık, ara ara pul şakırtısı
    for _ in range(sure // 3):
        t0 = rng.uniform(0, sure) * SR
        for k in range(rng.integers(2, 5)):
            ekle(x, tok(rng.uniform(1800, 2600), 0.06, 0.012) * 0.9, t0 + k * rng.uniform(0.05, 0.11) * SR)
    for _ in range(sure // 2):
        ekle(x, tok(rng.uniform(900, 1300), 0.05, 0.01) * 0.6, rng.uniform(0, sure) * SR)
    # çay bardağı / kaşık şıngırtısı
    for _ in range(sure // 4):
        t0 = rng.uniform(0, sure) * SR
        for k in range(rng.integers(2, 4)):
            ekle(x, tok(rng.uniform(4200, 5200), 0.4, 0.08, 2) * 0.35, t0 + k * 0.13 * SR)
    return x


def hastane(sure=30):
    n = sure * SR
    t = np.arange(n) / SR
    # havalandırma uğultusu (döngüye tam bölünen frekanslar)
    x = suzgec(rng.standard_normal(n), alcak=400) * 0.5
    x += 0.12 * np.sin(2 * np.pi * 60 * t) + 0.05 * np.sin(2 * np.pi * 120 * t)
    # uzak hasta monitörü bipi (her 1 sn, kısık)
    bip = np.sin(2 * np.pi * 1000 * np.arange(int(0.09 * SR)) / SR) * zarf(int(0.09 * SR), 0.004, 0.05)
    for s in range(sure):
        ekle(x, bip * 0.18, (s + 0.3) * SR)
    # koridorda uzak ayak sesleri
    for _ in range(3):
        t0 = rng.uniform(0, sure)
        for k in range(8):
            ekle(x, suzgec(rng.standard_normal(int(0.05 * SR)), alcak=1200) * zarf(int(0.05 * SR), 0.002, 0.015) * 0.5,
                 (t0 + k * 0.55) * SR)
    # anons "ding-dong" (bir kez)
    for k, f in enumerate([784, 622]):
        ekle(x, tok(f, 1.2, 0.5, 2) * 0.25, (12 + k * 0.55) * SR)
    return x


# makam havası: Uşşak dizisi (La-Si♭yarım-Do-Re-Mi-Fa-Sol) — yaklaşık, eşit aralıklı
DIZI = [220.0, 238.0, 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 476.0, 523.3]


def mizrap(frek, sure, sonum=0.9):
    """Bağlama/ud benzeri telli ses (Karplus-Strong)."""
    n = int(sure * SR)
    p = max(2, int(SR / frek))
    tampon = rng.uniform(-1, 1, p)
    cik = np.zeros(n)
    kayip = 0.996 if sonum > 0.6 else 0.990
    bloklar = []
    for _ in range(n // p + 1):  # periyot periyot (hızlı) Karplus-Strong
        bloklar.append(tampon)
        tampon = kayip * 0.5 * (tampon + np.roll(tampon, -1))
    cik[:] = np.concatenate(bloklar)[:n]
    return cik * zarf(n, 0.002, sonum * 2)


def muzik(sure, tempo, gece):
    n = int(sure * SR)
    x = np.zeros(n)
    vurus = 60 / tempo
    # dem (drone): Re + La, yumuşak
    t = np.arange(n) / SR
    dem = 0.08 * np.sin(2 * np.pi * 110 * t) + 0.05 * np.sin(2 * np.pi * 165 * t)
    x += dem * (0.6 if gece else 0.4)
    # ezgi: dizide küçük adımlarla gezinen, cümle sonu La'ya dönen
    adim = int(sure / vurus)
    yer = 0
    for i in range(adim):
        cumle = i % 16
        if cumle == 15:
            yer = 0
        elif rng.random() < (0.35 if gece else 0.75):
            yer = int(np.clip(yer + rng.choice([-2, -1, -1, 1, 1, 2]), 0, len(DIZI) - 1))
        else:
            continue
        uz = vurus * (2 if cumle in (7, 15) else 1)
        nota = mizrap(DIZI[yer] * (0.5 if gece else 1), uz + 0.6, 0.5 if gece else 0.35)
        ekle(x, nota * (0.45 if gece else 0.55), i * vurus * SR)
        if not gece and cumle % 4 == 0:  # bas mızrap
            ekle(x, mizrap(110, vurus * 2, 0.6) * 0.35, i * vurus * SR)
    if gece:
        x = suzgec(x, alcak=2500)
    return x


def uyuma(sure=2.0):
    """Uyurken: yumuşak, inen üç nota + hafif nefes."""
    n = int(sure * SR)
    x = np.zeros(n)
    for k, f in enumerate([659.3, 523.3, 392.0]):
        ekle(x, tok(f, sure - k * 0.4, 0.6, 2) * 0.5, k * 0.4 * SR)
    nefes = suzgec(rng.standard_normal(n), alcak=800, yuksek=200) * np.sin(np.pi * np.arange(n) / n) ** 2 * 0.15
    x[: n] += nefes[: n]
    x[-int(0.05 * SR):] *= np.linspace(1, 0, int(0.05 * SR))
    return x


def gorev_tamam():
    x = np.zeros(int(1.2 * SR))
    for k, f in enumerate([523.3, 784.0]):
        ekle(x, mizrap(f, 1.0 - k * 0.15, 0.3) * 0.7, k * 0.14 * SR)
    for k in range(6):  # pırıltı
        ekle(x, tok(rng.uniform(2500, 4000), 0.25, 0.05, 2) * 0.15, (0.3 + k * 0.06) * SR)
    x[-2000:] *= np.linspace(1, 0, 2000)
    return x


def terfi():
    x = np.zeros(int(2.5 * SR))
    notalar = [(293.7, 0.0), (349.2, 0.12), (440.0, 0.24), (587.3, 0.36), (587.3, 0.75)]
    for f, t0 in notalar:
        ekle(x, mizrap(f, 1.6, 0.45) * 0.6, t0 * SR)
        ekle(x, mizrap(f * 2, 1.0, 0.3) * 0.2, t0 * SR)
    for t0 in [0.0, 0.24, 0.36, 0.5, 0.75]:  # darbuka "düm/tek"
        n = int(0.15 * SR)
        dum = np.sin(2 * np.pi * 90 * np.arange(n) / SR) * zarf(n, 0.002, 0.06)
        ekle(x, dum * 0.6, t0 * SR)
    x[-3000:] *= np.linspace(1, 0, 3000)
    return x


if __name__ == "__main__":
    CIKIS = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(CIKIS, exist_ok=True)
    kaydet("uyuma", uyuma())
    kaydet("kahvehane", kahvehane())
    kaydet("hastane", hastane())
    # müzik: 16 vuruşluk cümlelere tam bölünür, son nota kuyruğu başa sarar (ekle) → dikişsiz
    kaydet("mahalle", muzik(48 * 60 / 96 * 1.0 * 2, 96, False), kanal=2)  # 96 vuruş = 60 sn
    kaydet("gece_muzik", muzik(32 * 60 / 60, 60, True), kanal=2)  # 32 sn
    kaydet("gorev_tamam", gorev_tamam())
    kaydet("terfi", terfi())
