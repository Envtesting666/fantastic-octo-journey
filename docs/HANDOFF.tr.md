# AI devir kaydı — önce bunu oku

Son durum: **8 Kasım 2026, M01 devam ediyor (görsel düzeltmeler + ölçümlü testler yapıldı).** Kullanıcı bu noktada başka bir AI'ın devam edebilmesi için devir istedi. Mevcut çalışan temeli koru; projeyi yeniden kurma. Önce README'nin en üstünü, sonra bu dosyayı oku.

## Kullanıcı ne istiyor?

- Godot'ta küçük ama özenli bir futbol şut oyunu. İlk kapsam: tek futbolcu, top, kaleci, saha; tam maç değil.
- FIFA'yı biraz hatırlatan yarı gerçekçi insan anatomisi ve grafik. Low-poly/çizgi film karakter istemiyor.
- Ana kalite hedefi: vücut ağırlığı, kol/bacak salınımı, destek ayağı, ayak–top teması ve kaleci uzanışı.
- Çok iyi ve ölçülerek optimize edilen kod; anlaşılır, yükseltilebilir parçalar. Gereksiz altyapıyla karmaşıklık yaratma.
- Bir seferde tek modül. README başında aktif iş, doğrulanan sonuç, eksik ve sonraki tek hedef görünsün.
- **UI, açılış menüsü ve giriş akışı SONRA.** Şimdi karakter/hareket/kamera. Top ve şut M02; kaleci M03.
- Mastery yaklaşımı: küçük somut iyileştirme → çalışan oyunda inceleme → açık eksik kaydı → tekrar düzeltme. Kalite veya performansı kanıtsız olmuş gibi anlatma.
- Kullanıcı planın ardından M01 üretimini açıkça başlattı. Rutin uygulama/düzeltmeler için yeniden genel izin isteme. Bu dosya yeni onay akışı değildir.

## Gerçekte ne var?

Çalışma kökü `C:\Game deneme`; Godot proje kökü `C:\Game deneme\game`.

- M00 tasarım belgesi tamamlandı.
- Godot 4.7.1 ile çalışan 3D sahne, insan model/iskeleti, idle/walk/run geçişi, kamera yönüne göre WASD hareketi, Shift koşu, fare kamera, R sıfırlama ve Esc fare yakalama.
- Kamera mesafesi 6,2 m, odak 1,05 m, görüş açısı 52°. İlk ayarlar; kalite açısından henüz kesinleşmedi.
- Kaynak karakter CC0, 1,8 m, 24 kemik, 262.348 üçgen; `walk` 1 saniye, `run` 0,625 saniye. Model Godot tarafından LOD'larla içe alınıyor.
- Idle duruşu kaynak A-pose'dan kolları indirerek oluşturuluyor; düşük genlikli nefes ve üst gövde dönüş eğimi ekleniyor.
- Forma/şort/çorap rengi shader ile; krampon ayrı GLB ve iki ayak kemiğine bağlı.
- Saha, basit bina, çevre direkleri, kale ve görsel ağ var. Bunlar M01 bağlamı; bitmiş çevre sanatı sayılmaz. Kalenin çarpışması yok.
- **Top, şut, kaleci, skor, UI, menü, ses ve kayıt sistemi YOK.**
- Git deposu başlatılmadı; commit veya PR yok. Çalışan uygulama açık bırakılmadı.

## Karakter (en güncel)

Oyuncu `game/assets/characters/footballer_mh.glb` (MakeHuman CC0, `tools/build_footballer.py`). Yeniden üretmek için:

```powershell
$env:BLENDER_USER_RESOURCES = 'C:Game deneme	oolscachelender_profile'
& 'C:Program FilesBlender FoundationBlender 5.2lender.exe' --background --python 'C:Game deneme	oolsuild_footballer.py'
```

Sonra Godot import. Animasyonlar: Quaternius UAL (CC0) insan profiliyle yeniden hedefleniyor. CMU vuruş BVH'leri `.source/mocap/cmu_subject10/` (henüz bağlı değil). Kullanıcı testlerin her değişiklikte koşturulmasını istemiyor.

## M02 durumu

Top, kale/ağ çarpışması, ip ağ, top sürme ve çim yenilemesi yapıldı (README tarihçesi). Testler: `tools/test_m02_ball.gd` (11/11), `tools/test_m01_motion.gd` (25/25). Sıradaki: vuruş animasyonu (destek ayağı → geri salınım → temas → devam) ve temas karesinde tek seferlik `ball.touch()`; sol tuş basılı tut/bırak ile güç. Top yalnızca `ball.touch()` ile itilir; ikinci bir kuvvet yolu ekleme.

## M01 açık maddeleri

Forma maskesi, krampon, kamera engeli ve ayak kayması 8 Kasım'da düzeltildi; ayrıntı README tarihçesinde. Yürüme–koşu faz eşlemesi de yapıldı. Ölçüm aracı: `tools/test_m01_motion.gd` (25/25 geçti).

Kalan M01 işleri:

1. Kullanıcı oyunu gerçek klavye/fareyle oynasın; forma, krampon, hareket ve kamera için açık kabul/değişiklik talebi alın. Sessizliği kabul sayma.
2. Kayma testi düz sabit hızda; hızlanma ve dönüş anını ölç (ör. test_gait penceresini ivmelenme sırasında al).
3. Yavaşlatılmış kayıtta uzuv deformasyonu ve dönüşte ayak kaymasını incele (test yalnızca düz koşuyu ölçüyor).
4. Kapsül ~1 cm zemine gömülü; krampon teması ile birlikte değerlendir.
5. Krampon sade (dil/yaka dolgusu yok); detail probe 0,459 hafif parlak. Kol kesimi dikey düzlem; ensede yakın planda ince iz.

**M02'ye veya UI'a atlama.**

## Dosya haritası

| Dosya | Sorumluluk |
| --- | --- |
| `game/project.godot` | Proje, giriş eylemleri, Forward+, fizik ve pencere ayarları |
| `game/world/training_ground.tscn` | Kaydedilmiş, düzenlenebilir ana sahne |
| `game/world/training_ground.gd` | Sahne düzeyinde sıfırlama |
| `game/world/pitch.gdshader` | Zemin çimi (uzak mesafe) |
| `game/world/grass_common.gdshaderinc` | Ortak saha rengi: biçme şeritleri, lekeler, çizgiler |
| `game/world/grass_shell.gdshader` | 16 katmanlı yakın çim (MultiMesh `GrassShells`), rüzgâr salınımı |
| `game/player/footballer.tscn` | CharacterBody3D, çarpışma ve değiştirilebilir görsel |
| `game/player/player_controller.gd` | İvme/fren/dönüş ve ölçülen yer değiştirmeye göre animasyon |
| `game/player/locomotion.gd` | Idle üretimi, tek AnimationTree, forma ve krampon bağlama |
| `game/player/body_balance.gd` | Küçük üst gövde eğimi; SkeletonModifier3D |
| `game/ball/ball.gd` | Top uçuşu/yuvarlanma, ağ tutma, sıfırlama; tek giriş `touch()` |
| `game/player/ball_control.gd` | Krampon erişimine göre top sürme dokunuşu |
| `game/world/goal_net.gd` + `goal_net.gdshader` | İp ağ: cep, sarkma, titreşim |
| `tools/test_m02_ball.gd` | Top/kale/ağ/sürme testi ve ağ görüntüleri (`evidence/m02`) |
| `game/camera/follow_camera.gd` | Fare kontrollü, interpolasyonlu hedef takibi |
| `game/assets/characters/football_kit.gdshader` | Kaynak dokular + forma/şort/çorap maskeleri |
| `tools/prepare_character.mjs` | Orijinal GLB'yi koruyup rest X/Y (UV2) ve Z (COLOR.r) ekler; forma panelleri shader'da |
| `tools/build_training_ground.gd` | Sahneyi deterministik olarak yeniden üretir; mevcut tscn'yi üstüne yazar |
| `tools/recipes/training_boot.json` | Düzenlenebilir krampon ölçü/parça tarifi |
| `tools/build_boot.py` | Asset Forge ile krampon .blend/.glb ve 4 QA görüntüsü üretir |
| `tools/capture_m01.gd` | Harici inceleme aracı; 4 genel + 4 yakın plan motor görüntüsü alır; gerçek fareden bağımsız |
| `tools/test_m01_motion.gd` | Harici ölçüm: hız, dönüş, durma, sınır, kamera engeli, fare, sıfırlama, ayak kayması, kare süresi |
| `tools/inspect_character.gd` | Harici model/iskelet/animasyon inceleme aracı |

## Çalıştırma komutları — PowerShell

Kurulu ve gerçekten çalıştırılmış motor:
`C:\Users\fatih\Desktop\son\Godot_v4.7.1-stable_win64_console.exe`

Başka yerde eski Godot 4.3 de var; bu projede 4.7.1 kullanıldı. Sisteme yeni motor yüklenmedi.

Her yeni PowerShell oturumunda sandbox dışına Godot ayarı yazmamak için:

```powershell
$env:APPDATA = 'C:\Game deneme\tools\cache\profile'
```

Oyunu aç:

```powershell
& 'C:\Users\fatih\Desktop\son\Godot_v4.7.1-stable_win64_console.exe' --path 'C:\Game deneme\game'
```

Yeni/değişen GLB veya shader sonrası import:

```powershell
& 'C:\Users\fatih\Desktop\son\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path 'C:\Game deneme\game' --import --quit
```

Derleme/başlangıç kontrolü (görsel kalite testi değildir):

```powershell
& 'C:\Users\fatih\Desktop\son\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:\Game deneme\game' --quit-after 120
```

Hareket/kamera/performans ölçümü (pencereli, rapor evidence/m01/motion_report.txt):

```powershell
& 'C:UsersatihDesktopsonGodot_v4.7.1-stable_win64_console.exe' --path 'C:Game denemegame' --resolution 1920x1080 --script 'C:Game deneme	ools	est_m01_motion.gd'
```

Sahne yeniden üretimi (tscn'yi üstüne yazar). **Pencereli çalıştır:** başsız modda MultiMesh verisi (ağ, çim katmanları) boş kaydedilir; script bunu reddeder:

```powershell
& 'C:UsersatihDesktopsonGodot_v4.7.1-stable_win64_console.exe' --path 'C:Game denemegame' --script 'C:Game deneme	oolsuild_training_ground.gd'
```

Güncel motor görüntülerini oluştur:

```powershell
& 'C:\Users\fatih\Desktop\son\Godot_v4.7.1-stable_win64_console.exe' --path 'C:\Game deneme\game' --script 'C:\Game deneme\tools\capture_m01.gd'
```

Karakter maskelerini kaynaktan yeniden üret:

```powershell
& 'C:\Program Files\nodejs\node.exe' 'C:\Game deneme\tools\prepare_character.mjs'
```

Kramponu yeniden üret (sonra Godot import gerekir):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python 'C:\Game deneme\tools\build_boot.py'
```

Blender işlemi canlı kullanıcı sahnesini değiştirmez. Script mevcut Asset Forge executor'ına bağlı:
`C:\Users\fatih\.agents\skills\asset-forge\scripts\forge.py`.
Başka bilgisayara taşınırsa bu bağımlılığı da taşı veya yeni ortamda skill'den çöz. Yeni Blender varlığı üretirken asset-forge skill'ini oku/kullan; elle primitif birleştirerek başka bir pipeline kurma.

## Teknik ayrıntılar ve doğrulama sınırları

- Donanım kayıt defterinden: i9-12900K, RTX 3090. Godot çıktısı da RTX 3090 ve Vulkan 1.4.341 / Forward+ gösterdi. CIM sorgusu sandbox'ta reddedildi, alternatif kayıt defteri okuması kullanıldı.
- Proje fizik 60 Hz, fizik interpolasyonu açık. Kamera render adımında interpolasyonlu oyuncu konumunu izliyor. Animasyon ağacı fizik kontrolcüsünden bir kez manuel ilerletiliyor.
- Kaynak iskelet Armature ölçeği **0,01**, kemik koordinatları santimetre; mesh gerçek boyu 1,8 m. Krampon kemiğe bağlanırken bu ölçek ve yerel eksen dönüşü `locomotion.gd` içinde hesaba katılıyor. Gelişigüzel ölçek uygulama.
- Animasyonun hızı karakterin gerçek yer değiştirmesinden geliyor; alan sınırında clamp sonrası yer değiştirme hesaplanıyor. Bu düzeltme kodda var ama sınır testi henüz yok.
- `capture_m01.gd` sentetik action girdisiyle yürütüyor. Son çıktı: `floor=true`, konum yaklaşık `(0, -0.009878, -7.160422)`. Yaklaşık 1 cm zemine gömülme ve krampon teması ayrıca değerlendirilmeli.
- Pencere/çıktı **1440×810**; ayarlardaki hedef viewport 1920×1080. 1080p 60 FPS başarılmış gibi yazma; FPS/kare süresi/CPU/GPU ölçümü yapılmadı.
- Son grafik capture koşusu başarıyla tamamlandı, script/shader hatası vermedi. İlk import eksik sahne varken yapılmıştı; o eski hatalar düzeltildi. Editor import bazen `Safe save failed` uyarısı verdi, yine de varlıklar import oldu ve oyun çalıştı. Virüs korumasını veya güvenlik ayarlarını değiştirme.
- Blender .blend kaydında kullanıcı thumbnail klasörüne yazma uyarısı verdi; .blend, .glb ve QA görüntüleri üretildi.
- Blender MCP bağlantısı denendi, addon'a bağlanamadı. Kurulu Blender CLI ile devam edildi; MCP için kullanıcıyı durdurmak gerekmiyor.
- Native Windows UI otomasyonu yapılmadı. Gerekirse `computer-use` skill'ini ve guidance/API belgelerini okuyup sky veya mevcut CUA araçlarını kullan.
- Dönüş, durma, sınır, kamera, reset, düz yürüme/koşu ayak kayması ve 1080p kare süresi yazılımsal girdiyle ölçüldü. Gerçek kullanıcı oynayışı, farklı FPS davranışı ve ara hızlarda kayma ölçülmedi. Karakter/krampon görselleri kullanıcı tarafından kabul edilmedi.

## Kaynaklar ve korunacak dosyalar

- İnsan modeli: [Grab3D Man Base Mesh](https://grab3d.com/models/characters/man-base-character/), [rigged GLB](https://grab3d.com/dl/man-base-character-rigged/man-base-character-rigged.glb).
- Lisans: CC0; `game/assets/characters/LICENSE.txt` ve `.source/character/LICENSE.txt`. Kaynak açıklaması AI/Meshy tabanlı model + Blender düzenlemesi olduğunu belirtiyor. Modeli elle baştan üretmiş gibi sunma.
- Orijinal GLB ve manifest: `.source/character/`. İşlenmiş çalışma kopyası `game/assets/characters/footballer.glb`.
- Düzenlenebilir krampon kaynağı: `.source/boots/training_boot.blend`; tarifi `tools/recipes/training_boot.json`. Henüz son kalite kabulü yok.
- `.source`, `tools`, `evidence` Godot import'undan `.gdignore` ile ayrıldı. `.source` ve `tools/cache` Git ignore'da. **Başka makineye taşırken orijinal kaynakları ayrıca koru.**
- Kullanıcının masaüstündeki genel game-assets kütüphanesi okundu; uygun futbolcu yoktu, oraya dosya yazılmadı.
- Ağ indirmesi ilk sandbox denemesinde DNS hatası verdi; izinli/escalated indirmeyle yalnızca CC0 model/lisans/manifest proje içine alındı. Ücretli içerik veya hesap kullanılmadı.
- Leo Gura kaynakları ve proje yorumu README'de ayrı. Felsefe özeti yazmayı uzatmak yerine mevcut oynanabilir parçayı iyileştir.

## Devam ederken

1. README üstünü ve son görüntüleri oku.
2. Forma maskesi + krampon kusurunu düzelt; kaynak tariflerini koru, yeniden import ve capture yap.
3. Hareket/dönüş/kamera/reset'i gerçek girdilerle kontrol et; ayak kaymasını incele ve ölçümlü performans kaydı oluştur.
4. README'nin güncel durumunu ve bu devir kaydını yeni kanıta göre güncelle. Gereken kontroller geçmeden M01'i tamamlandı işaretleme.
