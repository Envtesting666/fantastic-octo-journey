# Futbol Şut Oyunu — Tasarım ve Geliştirme Kaydı

Son güncelleme: 8 Kasım 2026  
Durum: M00 tamamlandı; M01 devam ediyor. İlk karakter, hareket, kamera ve antrenman sahnesi çalışıyor; görsel ve hareket kalite kontrolü sürüyor.  
Motor: Godot 4.7.1, Vulkan / Forward+. Windows PC, klavye ve fare. Geliştirme donanımı: i9-12900K / RTX 3090.  
Ad: Son Vuruş, geçici proje adı.

Bu README, projenin ortak hafızasıdır. Gereksinimler, öneriler, açık kararlar ve gerçekten tamamlanan işler ayrı tutulur. Her anlamlı çalışma sonunda güncellenir. Geliştirici kaydı oyuncunun arayüzüne eklenmez.

## Şu an neredeyiz?

**Aktif modül: M02 — top (ilk adım bitti; sıradaki: vuruş animasyonu ve şut).** Kullanıcı 8 Kasım'da M01 kabulünü beklemeden M02'ye geçmeyi seçti; M01'in açık maddeleri aşağıda kayıtlı.

- **Son yapılan:** Forma panelleri piksel başına kesiliyor (rest konumu UV2/COLOR'da; numara ve altın süs kaldırıldı). Krampon yeni tarifle yeniden üretildi (yan profil ∩ ayak planı ∩ kubbe kesiti). Kamera katı sahneye girince öne çekiliyor; kulübeye çarpışma eklendi. Klip zemin hızları ölçülüp yürüme 1,5 / koşu 4,5 m/s'ye ayarlandı. Yürüme ve koşu klipleri ortak 1 saniyelik döngüye gerilerek faz eşlendi.
- **Doğrulanan:** [Hareket raporu](../evidence/m01/motion_report.txt), 1920×1080, RTX 3090: 25/25 kontrol geçti. Basan ayak kayması yürüyüşte %0–1, koşuda %1, karışım bölgesindeki ara hızlarda (2,4 ve 3,4 m/s) %1–3 (ilk ölçüm: yürüyüş %10–15, koşu %35). 90° dönüş 1,12 s, koşudan durma 0,57 s / 1,23 m; sınırda ayaklar duruyor; sıfırlama ve fare açıları doğru. Vsync kapalı kare süresi ort. 1,06 ms, p95 1,52 ms, 186 çizim çağrısı.
- **Bilinen eksikler:** Testler gerçek tuş eylemlerini yazılımla tetikliyor; insan oynayışı ve yavaşlatılmış kayıt incelemesi yapılmadı. Kayma yalnızca düz, sabit hızda ölçüldü; dönüş ve hızlanma anı ölçülmedi. Kapsül ~1 cm zemine gömülü. Krampon hâlâ sade (dil/yaka dolgusu yok). Kol kesimi dikey düzlem; ensede yakın planda ince iz var. Görseller kullanıcı tarafından kabul edilmedi.
- **Son görsel iş:** 16 katmanlı yakın çim (2,5 cm yaprak, rüzgâr), yumuşak saha lekeleri, forma kumaş dalgası (hıza bağlı), kamera 7,4 m. Kale ağı ilk kez görünüyor (eski hata: başsız üretimde ağ verisi boş kaydediliyordu). Kare süresi p95 2,58 ms.
- **Sıradaki tek hedef:** Kullanıcının oyunu oynayıp forma/krampon/hareket hakkında geri bildirim vermesi; ardından yavaşlatılmış kayıtla dönüşte/hızlanmada ayak ve uzuv incelemesi.
- **Başka AI için:** Önce [DEV_HANDOFF.md](HANDOFF.tr.md) dosyasını oku. Komutlar, dosya haritası ve kaldığımız nokta orada.
- **Son gerçek görüntü:** [Arkadan duruş](../evidence/m01/01_idle_rear.png) · [Önden duruş](../evidence/m01/02_idle_front.png) · [Yürüyüş](../evidence/m01/04_walk.png) · [Forma yakın](../evidence/m01/closeup/kit_rear.png) · [Krampon oyunda](../evidence/m01/closeup/boots_front.png) · [Krampon stüdyo](../evidence/m01/boots/hero.png).

### Modül yolu

| Modül | Amaç | Tamam sayılma koşulu | Durum |
| --- | --- | --- | --- |
| M00 · Konsept | Kontrol, kamera, platform ve ilk kapsam | İlk oynanabilir deneyimin kısa ve açık tarifi kaydedildi | Tasarım tamamlandı |
| M01 · Karakter temeli | İnsan model, iskelet, duruş, hareket, kamera ve basit ışık | Oyunda hareket/dönüş incelendi; belirgin ayak kayması, bozuk uzuv veya kamera engeli kaydedilip giderildi | Devam ediyor; ölçümlü hareket/kamera testleri geçti, insan oynayışı ve görsel kabul bekleniyor |
| M02 · Vuruş ve top | Yaklaşma, destek ayağı, geriye salınma, temas ve vuruş sonrası denge | Tek şut baştan sona çalışıyor; temas anı ve top fiziği birlikte incelendi | Devam ediyor: top, kale/ağ ve top sürme çalışıyor; şut yok |
| M03 · Kaleci | Hazır duruş, konumlanma, uzanma, kurtarış ve toparlanma | Kaleci topa erişimine uygun tepki veriyor; kurtarış görünür temasla tutarlı | Planlandı |
| M04 · Oyun döngüsü | Pozisyon, şut, sonuç, hızlı tekrar; ardından UI | Gol/kurtarış/dışarı sonuçlarıyla tekrar oynanabiliyor; farklı kararlar denenebiliyor | Planlandı |
| M05 · Sunum ve iyileştirme | Saha, malzemeler, ışık, ses ve performans | Seçilen donanımda oynayış ve ölçümler kaydedildi; bilinen eksikler listelendi | Planlandı |

Görsel kalite M01'den itibaren incelenir; M05 tüm parçaların son uyumuna ayrılır. Modüller iş sırasını gösterir; ayrı paketler veya karmaşık altyapılar gerektirmez. Gözlenen bir sorun önceki modüle dönmeyi gerektirebilir. Yeni özellikler önce aday listesine yazılır; aynı anda bir ana hedef üzerinde çalışılır.

## Kullanıcının belirlediği gereksinimler

- Üretime geçmeden önce oyunun nasıl oynanacağını birlikte planlamak.
- Futbolcu görünümünde, insan anatomisi ve spor kıyafeti okunabilen bir oyuncu karakteri.
- Kaleci görünümünde, rolü görünüşünden ve hareketlerinden anlaşılabilen bir kaleci.
- FIFA'yı bir miktar hatırlatan futbol sunumu; en üst düzey fotogerçekçilik hedefi olmadan iyi grafikler.
- Görünür köşeli yüzeylerin belirlediği low-poly bir estetik kullanılmaması.
- Sade, anlaşılır ve özenli kullanıcı arayüzü.
- Sofistike oynanış ve profesyonel işçilik hedefi.
- Leo Gura'nın mastery yaklaşımından beslenen, sabırlı ve derinlemesine çalışma düzeni.
- Eklenenler, değişiklikler ve üzerinde çalışılan konuların README'de tutulması.
- Modül modül ilerlemek; aktif işi ve sonraki adımı kolayca takip etmek.
- Gerçekçi vücut hissi: kol/bacak salınımı, gövde dönüşü, ağırlık aktarımı ve vuruşa hazırlık.
- Ayak–top temasının animasyonla ve topun fiziksel tepkisiyle örtüşmesi.
- Grafik ve hareket kalitesini başlangıçtan itibaren gözetmek.
- Model, animasyon ve oynanışı sonradan geliştirebilecek kadar ayrılmış, anlaşılır bir proje yapısı.
- Açılış ekranı, giriş akışı ve UI sonraya bırakılacak; ilk üretim doğrudan oyun sahnesine odaklanacak.
- Yüksek kod kalitesi ve performans; anlaşılır ve geliştirilebilir yapı korunacak.

## M00 — İlk oynanışın tarifi

**Çekirdek fikir: İyi şut, yaklaşma açısının ve vücut dengesinin sonucudur.** Oyuncu küçük bir antrenman alanında futbolcuyu hareket ettirir, kalecinin konumunu okur, açısını oluşturur ve vuruşunu yapar. Sonucu gördükten sonra yeni bir yaklaşım dener.

İlk çalışma yönü: Windows PC, klavye/fare, karakterin arkasından hafif yüksek kamera, sınırlı alanda serbest hareket, tek temel ayak üstü vuruş. Bunlar önceki öneri ve kullanıcının devam talebi temelinde seçilen, ilk oynayıştan sonra değiştirilebilir başlangıç kararlarıdır. Her ayrıntı kullanıcı tarafından ayrı ayrı onaylanmış sayılmaz.

### Bir deneme nasıl geçer?

1. Uygulama doğrudan antrenman sahasına açılır; açılış menüsü üretilmez.
2. Futbolcu topa yaklaşır, kısa dokunuşlarla şut açısını oluşturur.
3. Oyuncu hedefi ve gücü seçer. Futbolcu destek ayağını koyar ve vuruşa geçer.
4. Top görünür ayak temasında fiziksel tepki alır. Kaleci konumuna ve erişimine göre kurtarmaya çalışır.
5. Gol, kurtarış veya dışarı sonucu oluşur; deneme başlangıç durumuna döndürülebilir.

M01 bu zincirin karakter ve kamera kısmını; M02 vuruş/top kısmını; M03 kaleciyi; M04 bütün döngüyü tamamlar. İlk modülde tüm zincirin çalışması beklenmez.

### Kararın derinliği

Oyuncu daha açık açı için hareket etmeyi veya gördüğü fırsatta erken vurmayı seçer. Gücü artırmak daha uzun hazırlık gerektirebilir; yaklaşma yönü ve gövdenin hizası seçilen hedefi etkiler. Bu ilişkiler ilk vuruş denemesinde ayarlanacak; görünmeyen rastgele isabet cezası kullanılmayacak. Hedef: Sonucun nedenini hareket ve top üzerinden anlayabilmek.

Tasarım hipotezi: Aynı pozisyonun birden fazla işe yarayan çözümü olursa tekrar denemek anlamlı olabilir. Bunun eğlenceli olduğu ancak oynanabilir denemeler ve kullanıcı geri bildirimiyle anlaşılabilir.

## Görsel çalışma yönü

**Yarı gerçekçi, temiz bir futbol sunumu.** Doğal insan oranları, yumuşak siluetler, tutarlı malzemeler ve okunaklı ışık temel alınır. Gerçekçilik düzeyi, oyun kamerasından değerlendirilir.

İlk sanat yönü: Günün son ışığında, bakımlı fakat kullanılmış hissi veren küçük bir antrenman tesisi. Sıcak yandan ışık, serin ve yumuşak gölgeler; doğal yeşil çim, koyu petrol mavisi futbolcu forması ve mat amber kaleci forması. Açık renk top hem zeminden hem karakterlerden ayrılır. İnce kullanım izleri ve kumaş yüzeyi yakın planda destekleyici ayrıntıdır; topun ve hareketin okunmasını bastırmaz.

Önce siluet, anatomi, hareket, ışık ve malzeme uyumu değerlendirilir. Çim yoğunluğu, kumaş mikrodetayı ve arka plan süsleri bunları desteklediği ölçüde eklenir. Bu bir tasarım seçimidir; henüz üretilmiş veya kullanıcı tarafından görsel olarak değerlendirilmiş değildir.

| Öğe | Önerilen kalite hedefi |
| --- | --- |
| Futbolcu | Atletik oranlar; forma, şort, çorap ve krampon; okunabilir yüz ve saç; doğal omuz, dirsek ve diz hareketleri |
| Kaleci | Ayrı forma ve eldivenler; hazır bekleme duruşu, yan adım, uzanma, kurtarış ve toparlanma hareketleri |
| Animasyon | Ayağın topa teması, destek ayağı, ağırlık aktarımı ve vuruş sonrası denge; koşuda ayak kaymasının kontrolü |
| Top ve kale | İnandırıcı ölçek; temas ve sekmenin okunması; direk, ağ ve top arasında tutarlı görsel/işitsel geri bildirim |
| Saha | Doğru saha ölçeği, okunabilir çizgiler, kontrollü çim ayrıntısı ve temas gölgeleri |
| Kamera | Futbolcuyu, topu ve kaleciyi karar vermeye yetecek açıklıkta gösteren açı |
| UI | Sınırlı sayıda gerekli bilgi, tutarlı yazı ve boşluklar; net güç/nişan geri bildirimi |

Model ayrıntısı ve doku bütçeleri kamera mesafesi ile hedef donanımdan sonra belirlenir. Kalite, poligon sayısı üzerinden tek başına değerlendirilmez; model, animasyon, ışık ve ses birlikte incelenir. Geçici test modelleri kullanılırsa açıkça geçici olarak kaydedilir.

## Vücut ve top için temel yaklaşım

Hedeflenen hareket zinciri: **yaklaşma → destek ayağını yerleştirme → bacağı geriye alma → ayak–top teması → bacağın devam hareketi → dengeyi toplama.** Gövde ve kollar bu zincire eşlik eder. Yalnızca bacağın dönmesi yeterli kabul edilmez.

Önerilen uygulama: İskelet animasyonları vücudun ana hareketini taşır; gerektiğinde ayak yerleşimi ve topa erişim için sınırlı düzeltmeler eklenir. Her uzvu ayrı fizik simülasyonuyla yönetmek ilk kapsamda önerilmiyor. Amaç anlaşılır kontrol ile inandırıcı hareketi birlikte kurmak.

- Topun hareketini tek fizik sistemi yönetir. Animasyon, şut komutu ve fizik birbirinden bağımsız olarak topa tekrar tekrar kuvvet uygulamaz.
- Vuruşun görsel temas anı ile fiziksel etkisi eşleştirilir; görünür erişim dışındaki topa şut uygulanmaz.
- Top sürme seçilirse topun ayağa yapışması yerine kısa temaslarla yönlendirilmesi hedeflenir.
- Destek ayağı, diz yönü, gövde dönüşü ve kollar oyun kamerasından ve yavaşlatılmış kayıtta incelenir.
- Kalecinin uzanması, topa teması ve toparlanması aynı bütünlükle ele alınır.

Bunlar kalite hedefi ve tasarım önerisidir; henüz uygulanmış veya doğrulanmış değildir.

## Sade ve geliştirilebilir proje yapısı

Üretim başladığında ihtiyaç oldukça oluşturulacak temel ayrım:

- **Oyuncu:** Kontrol ve hareket; değiştirilebilir görsel model/animasyon bölümü.
- **Top:** Fizik, temas ve şut etkisi.
- **Kaleci:** Karar verme ile görsel hareketin ayrılması.
- **Antrenman sahnesi:** Sahneyi, pozisyonu ve denemenin sonucunu birleştirir.
- **UI:** Gerekli bilgiyi ve yeniden denemeyi gösterir.

Şut gücü, topun sekmesi ve dönüş hızı gibi ayarlar ilgili parçanın düzenlenebilir verilerinde tutulur. Model değiştirmek top fiziğini yeniden yazmayı gerektirmemeli. Aynı ayarın birden fazla yerde farklı kopyası tutulmaz. Yeni klasör, soyutlama veya eklenti gerçek bir ihtiyaç çıktığında eklenir. Mevcut üretim yalnızca karakter, kamera ve saha bölümlerini içeriyor; top, kaleci ve UI henüz yazılmadı.

## Başlangıç kontrolleri ve kamera

| Girdi | İlk görev |
| --- | --- |
| WASD / sol çubuk / D-pad | Kamera yönüne göre yürüme ve dönüş; analog çubukta ara hızlar |
| Shift / RT | Koşu |
| Fare / sağ çubuk | Sınırlandırılmış yatay/dikey kamera |
| Sol tuşu basılı tut / bırak | Planlandı: Vuruş gücünü hazırla / vuruşu başlat. Henüz uygulanmadı. |
| R / View (Back) | Oyuncuyu ve topu sıfırla |
| Esc | Fareyi serbest bırak / yeniden yakala |

Kamera futbolcunun arkasından ve hafif yukarıdan topu, destek ayağını ve kaleyi birlikte gösterir. Takip yumuşatma miktarı kontrolü geciktirmeyecek biçimde ayarlanır. Şut sırasında zorunlu kamera kesmesi yapılmaz. Kamera mesafesi ve görüş açısı model sahneye alındıktan sonra gerçek görüntü üzerinden seçilecek.

Tuşlar Godot eylemlerine bağlanır; oyun mantığı fiziksel tuş adlarına dağıtılmaz. İlk dilimde gamepad, kontrol ayar ekranı ve güç göstergesi yapılmaz. Kontrollerin nihai hissi oynayışla belirlenecek.

## İlk oynanabilir kapsam — taslak

- Bir futbolcu, bir kaleci, bir top, bir kale ve tek saha.
- Sınırlı alanda serbest hareket ve çalışan tek temel ayak üstü vuruş.
- Şut öncesi konumlanan ve topa görünür hareketlerle tepki veren kaleci.
- Gol, kurtarış ve dışarı çıkma sonuçları; hızlı yeniden deneme.
- Temel deneyim değerlendirildikten sonra farklı mesafe ve açılardan üç pozisyon.

Falso, aşırtma, gelişine vuruş, frikik barajı, ilerleme sistemi ve farklı sahalar sonraki adaylardır. Tam maç, takım yönetimi, çevrimiçi oyun ve kariyer modu ilk çalışma kapsamına alınmadı. Açılış ekranı, giriş akışı ve oyuncu UI'ı temel oynayıştan sonra ele alınacak.

## Kod kalitesi ve performans düzeni

- **Net sorumluluk:** Hareket, animasyon, top fiziği ve kaleci kararları kendi parçalarında tutulur; tek dev betikte birleşmez.
- **Tek doğruluk kaynağı:** Topun hareketini tek sistem, vuruşun temasını tek olay yönetir. Aynı şut iki kez uygulanmaz.
- **Kolay ayar:** Hız, dönüş, şut ve kamera değerleri açık adlarla düzenlenebilir tutulur. Oynayışın içine açıklamasız sayılar dağılmaz.
- **Sabit fizik:** Hareket ve temas fiziğin zaman adımına göre yürür; görsel takip ayrı değerlendirilir. Farklı görüntü hızlarında aynı şutun davranışı kontrol edilir.
- **İhtiyaç kadar iş:** Sahne aramaları ve varlık yükleme tekrar eden güncelleme döngülerine konmaz. Sık kullanılan referanslar saklanır; olaylar uygun olduğunda sinyallerle aktarılır.
- **Ölçüme göre iyileştirme:** Godot profiler ile işlemci, fizik ve çizim maliyetleri incelenir. Karmaşık bir optimizasyon, ölçülen sorunu çözüyorsa eklenir.
- **Anlamlı doğrulama:** Çifte temas, yeniden başlatma durumu, animasyon/fizik uyumu ve kare hızından bağımsızlık gibi gerçek davranışlar kontrol edilir. Her küçük görsel ayar için test altyapısı büyütülmez.
- **Yükseltilebilir varlıklar:** Kaynak model/animasyonlar korunur; görsel varlık değişikliği oynanış mantığını değiştirmeden yapılabilmelidir.

İlk ölçüm hedefi: Geliştirme bilgisayarında 1920×1080 çözünürlükte 60 FPS için 16,7 ms kare bütçesi. İlk ölçüm (8 Kasım 2026, M01 sahnesi, i9-12900K / RTX 3090, Vulkan/Forward+, vsync kapalı, 900 kare koşu/dönüş): ort. 1,06 ms, p95 1,52 ms. Bu yalnızca bugünkü sade sahnenin ölçümüdür; top, kaleci ve çevre eklendikçe tekrarlanır. CPU/GPU ayrımı henüz profilleyiciyle incelenmedi.

## Çalışma felsefesi ve kaynaklar

Leo Gura'nın [Mastery](https://www.actualized.org/articles/mastery) yazısı, George Leonard'ın kitabını temel alarak sabırlı pratiği, gerçekçi beklentileri ve ilerlemenin duraklama dönemlerini ele alır. [Inner Game of Career Development](https://www.actualized.org/articles/inner-game-of-career-development) yazısında Gura, oyun tasarımı deneyiminden hareketle mekanikleri uygulamalı geliştirmenin önemini tartışır. Bu iki yazı 8 Kasım 2026 tarihinde okundu; kitap bütünüyle okunmuş değildir.

Aşağıdaki kurallar bu projeye ait uygulama yorumlarıdır; Gura'nın doğrudan futbol tasarım talimatları değildir:

1. **Bir soruya odaklan:** Her çalışma için oyuncunun yaşadığı somut problemi tanımla. Örnek: "Topa temas anı anlaşılmıyor."
2. **Küçük bir çözüm üret:** Tek seferde değerlendirilebilir bir değişiklik yap. Çözülmemiş çekirdeğin üzerine özellik yığma.
3. **Gerçek oyunda incele:** Ekran görüntüsü, hareket kaydı ve oynayışla sonucu değerlendir. Konsept görselini çalışan oyun kanıtı sayma.
4. **Kalitenin nedenini yaz:** Örneğin "ayak topa değmeden top hareket ediyor" gibi gözlemler kaydet; yalnızca "daha iyi olsun" deme.
5. **Tekrar düzelt:** Aynı mekaniği gözlenen soruna göre iyileştir. Yeni bir özellik ancak deneyime katkısı açıklanabiliyorsa plana alınır.
6. **Geri bildirimi koru:** Kullanıcının kabul ettiği ve değiştirmek istediği yönleri açıkça kaydet. Sessizliği kabul sayma.
7. **Kanıtı doğru adlandır:** Planlanan, uygulanan ve doğrulanan işleri ayır. Performans hedefleri ölçüm olmadan başarılmış sayılmaz.

Mastery burada bir çalışma disiplini hedefidir. Henüz ulaşılmış bir ustalık veya garanti edilmiş kalite iddiası değildir.

## İleride kullanılacak değerlendirme soruları

- Oyuncu nişanının ve gücünün sonucu nasıl etkilediğini anlayabiliyor mu?
- Aynı koşulda sonuçlar öğrenmeye elverecek kadar tutarlı mı?
- Futbolcunun ayağı ile topun ayrılma anı örtüşüyor mu?
- Kaleci konum, tepki ve erişim sınırlarıyla anlaşılabilir davranıyor mu?
- Karakterler oyun kamerasından futbolcu ve kaleci olarak okunuyor mu?
- Bir pozisyonda farklı kararlar anlamlı sonuçlar doğuruyor mu?
- Kullanıcı tekrar denemek istiyor mu? Bu soru gerçek geri bildirimle yanıtlanacak.
- Seçilen donanımda kare süresi, giriş tepkisi ve görsel netlik hedefleri karşılanıyor mu?

## Güncel çalışma kaydı

### Tamamlanan

- Çalışma klasörü incelendi; mevcut oyun veya belge bulunmadı.
- Bu README oluşturuldu.
- Kullanıcının görsel gereksinimleri, önerilen oyun yönü ve açık kararlar kaydedildi.
- Mastery ile ilgili iki birincil kaynak okundu ve proje yorumundan ayrıldı.
- Modül tablosu, aktif iş özeti ve tamamlanma ölçütleri eklendi. Bu, oyun modüllerinin tamamlandığı anlamına gelmez.
- Kullanıcının doğal vücut, temas fiziği ve sade/geliştirilebilir yapı talepleri kaydedildi.
- M00: İlk deneyim, platform, kontroller, kamera, sanat yönü ve başlangıç kapsamı yazıldı.
- UI/açılış ekranının sonraya bırakılması ve ölçüme dayanan kod/performans ilkeleri kaydedildi.
- M01 ilk uygulaması: Godot projesi, iskeletli kaynak insan modeli, hareket kontrolü, animasyon geçişleri, takip kamerası ve saha.
- CC0 kaynak modelin orijinali ve lisansı korundu; forma maskesi üreteci ile krampon JSON tarifi eklendi.
- Gerçek motor görüntüleri üretildi; bunlar ilk inceleme kanıtıdır, nihai görsel kalite kabulü değildir.

### Şu anda üzerinde çalışılan

- M01: Kullanıcı oynayışı ve görsel kabul; yavaşlatılmış kayıtla dönüş/hızlanmada ayak ve uzuv incelemesi.
- Kullanıcı başka bir AI'ın devam edebilmesi için pratik devir kaydı istedi; [DEV_HANDOFF.md](HANDOFF.tr.md) hazırlandı.

### Açık kararlar

- Kaynak insan modelinin futbolcu olarak görsel uygunluğu; henüz kullanıcı tarafından kabul edilmedi.
- Model/animasyon iyileştirmeleri ve gerekirse sonraki varlık bütçesi.
- Kamera mesafesi ve görüş açısının gerçek oynayışta değerlendirilmesi.
- Vuruşa hazırlık, hareket ve şut gücü arasındaki ilişkinin oynayışta ayarlanması.

### Sonraki adım

Kullanıcı oynayıp geri bildirim verir; sonra yavaşlatılmış kayıtla dönüş/hızlanma incelemesi. M01'in koşulları karşılanmadan M02'ye geçme. UI ve açılış ekranı sonraya bırakıldı.

## Güncelleme biçimi

Her anlamlı çalışma sonunda bu dosyanın güncel durumunu ve aşağıdaki tarihçeyi güncelle:

- Eklenen / değişen / kaldırılan.
- Doğrulanan ve nasıl doğrulandığı; varsa gerçek kayıt dosyasının bağlantısı.
- Bilinen eksikler ve açık kararlar.
- Üzerinde çalışılan konu ve sıradaki adım.
- Kullanıcının açık kabulü veya değişiklik talebi.

Önce en üstteki **Şu an neredeyiz?** bölümü ve modül tablosu güncellenir. Tamamlandı durumu yalnızca belirtilen koşul gerçekten incelendikten sonra verilir. İlerleme için tahmini yüzdeler kullanılmaz.

### 8 Kasım 2026

- Eklendi: İlk tasarım ve geliştirme kaydı.
- Doğrulandı: Klasörün başlangıçta boş olduğu; henüz oyun uygulanmadığı.
- Kullanıcı yönlendirmesi: Önce birlikte planlama; gerçek futbolcu ve kaleci görünümü; low-poly olmayan grafik; sade UI; README takibi; mastery odaklı çalışma.
- Bekleyen: Önerilen kontrol, kamera, görsel ayrıntılar ve ilk kapsam henüz kullanıcı tarafından seçilmedi.

### 8 Kasım 2026 — Modüler çalışma düzeni

- Eklendi: M00–M05 yol haritası, görünür güncel durum, her modül için tamamlanma koşulu.
- Eklendi: Vücut hareket zinciri, ayak–top temas ilkeleri ve geliştirilebilir temel parça ayrımı.
- Kullanıcı yönlendirmesi: Karmaşıklıkta kaybolmadan modül modül ilerlemek; grafik, vücut ve top temasını temelden iyi kurmak; ileride yükseltilebilir yapı.
- Doğrulandı: Bu değişiklik belgelendirmedir; çalışan oyun, karakter veya fizik üretildiği iddia edilmiyor.
- Sonraki: M00 kontrol/kamera/platform kararları; ardından M01 karakter ve hareket temeli.

### 8 Kasım 2026 — M00 tasarım çıktısı

- Kullanıcı yönlendirmesi: M00'a başlamak, UI/açılışı sonraya bırakmak; yaratıcı ve güçlü grafikler; yüksek kod kalitesi ve optimizasyon.
- Eklendi: İlk oynayışın adımları, PC/klavye-fare başlangıcı, hareket ve kamera tasarımı, tek temel şut ve antrenman tesisi sanat yönü.
- Eklendi: Kod sorumlulukları, fizik/animasyon eşlemesi, ayarlanabilir değerler ve ölçüme dayalı performans düzeni.
- Doğrulandı: M00'un belge çıktısı tamamlandı. Çalışan oyun veya performans sonucu üretilmedi.
- Ortam notu: Bu oturumdaki PATH aramasında Godot veya Blender komutu bulunmadı. Bu, uygulamaların bilgisayarda kurulu olmadığını kanıtlamaz; kurulum doğrulaması M01'de yapılacak.
- Sonraki: M01 — karakter ve hareket temeli.

### 8 Kasım 2026 — M01 ilk uygulama ve devir

- Eklendi: Çalışan Godot projesi, karakter/hareket/animasyon/kamera betikleri, düzenlenebilir saha ve malzemeler.
- Eklendi: Lisanslı kaynak model, kaynak hazırlama aracı, Asset Forge krampon tarifi, gerçek motor ve krampon görüntüleri.
- Doğrulandı: Godot 4.7.1, Vulkan/Forward+, RTX 3090 üzerinde sahnenin açılması ve görüntü alınması; sentetik hareket girdisinden sonra karakterin zeminde kalması.
- Eksik: Görsel kusurlar, gerçek kullanıcı girdileriyle oynayış, yürüyüşte ayak kayması, farklı kare hızları, tam sıfırlama ve ölçümlü performans doğrulaması.
- Kullanıcı yönlendirmesi: Başka bir AI kaldığı yerden devam edebilsin; pratik devir dosyası oluştur.
- Devir: [DEV_HANDOFF.md](HANDOFF.tr.md). M01 devam ediyor, M02 başlamadı.

### 8 Kasım 2026 — M01 forma, krampon, hareket ve kamera doğrulaması

- Değişti: Forma maskeleri vertex başına değil, piksel başına (`fwidth`) kesiliyor. `prepare_character.mjs` rest X/Y'yi UV2'ye, rest Z'yi COLOR.r'ye yazıyor; panel sınırları `football_kit.gdshader` içinde düzenlenebilir uniform. Yuvarlak yaka, ense yüksekliği ve koltuk altı düzeltildi. Pürüzlü sırt numarası ve altın yaka/kol süsü kaldırıldı; numara gerekirse aynı rest koordinatlarıyla shader'da çizilebilir.
- Değişti: Krampon tarifi yan profil ∩ ayak taban planı ∩ kubbe kesiti; topukta dar, parmak kökünde geniş, yuvarlak burun, 12 krampon dişi, bağcıklar üst yüzeyin üstünde. Ağırlıklı normal cilası kapatıldı (büyük yüzeyleri fasetli gösteriyordu). Stüdyo probe: hero 0,392, opposite 0,275, profile 0,153 geçti; detail 0,459 (sınır 0,45) hafif parlak.
- Eklendi: Kamera odak→göz ışını; katı engelde göz öne çekiliyor. Kulübeye çarpışma kutusu (`build_training_ground.gd`, sahne yeniden üretildi). Çitlerin çarpışması yok, içinden bakılabiliyor.
- Değişti: Ölçülen klip zemin hızları: yürüme 1,47, koşu 5,2 m/s. Oyuncu yürüme 1,5, koşu 4,5 m/s (ilk ayar).
- Eklendi: `tools/test_m01_motion.gd` — tuş eylemleriyle hız, dönüş, durma, sınır, kamera engeli, fare, sıfırlama, ayak kayması ve kare süresi; rapor `evidence/m01/motion_report.txt`. `capture_m01.gd` gerçek fareden bağımsız ve yakın plan çekimleri alıyor.
- Doğrulandı: 16/16 kontrol (yukarıdaki değerler). Yalnızca yazılımsal girdi; insan oynayışı değil.
- Eksik: Faz eşlemesi, ~1 cm gömülme, krampon detayı, kullanıcı görsel kabulü. M01 tamamlanmadı; M02 başlamadı.

### 8 Kasım 2026 — Yürüme–koşu faz eşlemesi

- Ölçüldü: İki klipte basma fazı aynı (sol ≈0,38, sağ ≈0,88); fark yalnızca süre (1 s / 0,625 s). Sync'li karışım bu yüzden ara hızlarda fazı kaydırıyordu.
- Değişti: `locomotion.gd` iki klibi ortak 1 saniyelik döngüye geriyor (`use_custom_timeline` + `stretch_time_scale`); adım saati = hız / karışıma göre döngü başına metre (yürüme 1,47 m, koşu 3,25 m).
- Eklendi: Test, analog %60/%80 girdiyle karışım bölgesini ölçüyor; her ayak için %5 kayma eşiği kontrol ediliyor.
- Doğrulandı: 25/25 kontrol. Kayma yürüyüş %0–1, koşu %1, ara hızlar %1–3. Kare süresi p95 1,24 ms.
- Eksik: Dönüş ve hızlanma anında kayma, insan oynayışı, görsel kabul. M01 tamamlanmadı.

### 8 Kasım 2026 — Çim, forma hareketi, kamera ve ağ hatası

- Kullanıcı yönlendirmesi: M02'den önce FIFA'daki gibi çim, rüzgârda/harekette dalgalanan forma, daha iyi grafik, oyuna uygun karakter boyu; top, kale ve ağ sordu.
- Eklendi: `grass_shell.gdshader` + `GrassShells` (16 katman, 42×60 m, 160 yaprak/m, 10–26 m arasında incelir, gölge atmaz). `grass_common.gdshaderinc` zemin ve katmanlarda aynı renk/çizgiyi verir; bloklu gürültü yerine yumuşak lekeler ve aşınma.
- Eklendi: Forma vertex dalgası: etek ve kol uçları gevşek, omuz/yaka sabit; genlik hıza bağlı (`cloth_motion` instance uniform). Gerçek kumaş simülasyonu değil: forma gövde ağına boyalı. Hareketli görüntüde henüz incelenmedi; yalnızca derlendi ve testler geçti.
- Değişti: Kamera mesafesi 6,2 → 7,4 m. Ölçek doğru (kale 7,32×2,44 m, karakter 1,80 m); "büyük" hissi yakın kameradan ve kaslı kaynak modelden. Model oranları değiştirilmedi.
- Düzeltildi: `build_training_ground.gd` başsız çalışınca MultiMesh dönüşümleri boş kaydediliyordu; kale ağı bu yüzden hiç görünmüyordu. Üreteç artık başsız modu reddediyor; sahne pencereli üretildi.
- Doğrulandı: 25/25 kontrol; kare süresi ort. 2,18, p95 2,58 ms (1080p, vsync kapalı). [Çim yakın](../evidence/m01/closeup/boots_front.png), [genel](../evidence/m01/01_idle_rear.png).
- Eksik: Kale hâlâ basit silindir, çarpışmasız. Genel görüntüde orta yuvarlakta dikey bir renk sınırı görülüyor, nedeni incelenmedi. Gökyüzü düz. Top M02.

### 8 Kasım 2026 — M02 ilk adım: top, kale/ağ, top sürme; çim ve ağ görünümü

- Kullanıcı yönlendirmesi: M02'ye başla. Çim çim gibi değil, ağ demir gibi; ip ağ topla etkileşmeli. En iyi kaynaklardan çim tekniklerini oku.
- Eklendi: `game/ball/` — 5 numara top (0,43 kg, r 0,11 m, içi boş küre ataleti), hava sürtünmesi 0,5·ρ·Cd·A, çimde yuvarlanma direnci 0,6 m/s², motor sönümü kapalı (tek kaynak). Özgün 12 panelli desen. Jolt fizik; dönüş sınırı 47 → 400 rad/s (eski sınır yuvarlanan topu kaydırıyordu).
- Eklendi: Direk/üst direk çarpışması; ağ çarpışması görsel ağın 0,2–0,3 m gerisinde, ağa değen top dışarı sekmiyor ve hızının %80'ini kaybediyor. Katmanlar: world / player / ball; kamera ışını yalnızca world.
- Eklendi: `player/ball_control.gd` — top yalnızca kramponun görünür erişiminde (toe kemiği) itiliyor; top oyuncudan 1,2 m/s hızlı gönderiliyor. Gövde yedeği: oyuncu topun içinden geçmez. R topu da sıfırlıyor.
- Eklendi: İp ağ — tek deforme olabilen mesh, altıgen göz (11 cm, 4 mm ip), yerçekimiyle sarkma, topun etrafında cep ve çarpma titreşimi (`goal_net.gd` + shader). Eski çubuk ağ kaldırıldı.
- Değişti: Çim — araştırılan kaynaklar (Ghost of Tsushima tekniklerinin Godot uyarlaması [2Retr0/GodotGrass](https://github.com/2Retr0/GodotGrass), [hexaquo grass serisi](https://hexaquo.at/pages/grass-rendering-series-part-2-full-geometry-grass-in-godot/)) uzun çim için yaprak geometrisi kullanıyor; 3 cm futbol çiminde kabuk katmanı korundu ve onların teknikleri uyarlandı: Voronoi öbekleri, yuvarlak yaprak normali, arkadan ışık geçirme, çok ölçekli gürültü rüzgârı, kökten uca renk. Biçme şeritleri bakış yönüne bağlı parlaklıktan; zemin mipmap'li gürültü dokusuyla taneli; yaprak seyrelmesi yaprak bazında rastgele (sert sınır yok).
- Düzeltildi: Test araçları gerçek klavye bağlarını siliyor; pencere odaktayken yazılan tuşlar sonuçları bozuyordu.
- Doğrulandı: [Top raporu](../evidence/m02/ball_report.txt) 11/11 — 2 m'den sekme 0,78 m; 10 m/s yer pası 52,9 m / 12,3 s; direk ve üst direkten dönüyor; ağ 25 ve 40 m/s şutu tutuyor; yürürken/koşarken top 0,4–2,7 m önde. Hareket testi 25/25; kare süresi p95 2,96 ms (1080p, vsync kapalı). Görseller: [genel](../evidence/m01/01_idle_rear.png), [ağ](../evidence/m02/net_impact.png), [çim yakın](../evidence/m01/closeup/boots_front.png).
- Eksik: Şut yok (vuruş animasyonu gerekiyor). Top sürme dokunuşu yürüme döngüsündeki ayak fazına göre zamanlanmıyor; kısa mesafede ayağa değmeden itme olabilir (gövde yedeği). Ağ ceplenmesi yalnızca durağan görüntüde incelendi. Çimde yakın planda hafif benekli görünüm var. Kullanıcı görsel kabulü yok.

### 9 Kasım 2026 — Oyun kolu, saha sınırı, çim görünürlüğü

- Kullanıcı geri bildirimi (oynadıktan sonra): Oyun kolu ekle; top haritadan çıktı; çimler belli olmuyor; oyuncu garip duruyor, FIFA gibi gerçekçi olmalı.
- Eklendi: Oyun kolu (Xbox düzeni, tüm cihazlar): sol çubuk/D-pad hareket, RT koşu, sağ çubuk kamera (2,6 rad/s), View sıfırlama. Hareket artık fare yakalamasına bağlı değil.
- Eklendi: Yalnızca topu tutan saha sınırı (layer "boundary", 3,2 m duvar, kenar ve çit hatlarında; kamera ve oyuncu etkilenmez); kapalı bordür halkası; top dünyanın altına düşerse başlangıca döner. Oyuncu sınırı ±18,5 / ±28,2 m (top hiçbir yerde ulaşılmaz kalmaz).
- Değişti: Çim — yapraklar biraz kalın/uzun (90/m, 3,5 cm), oyun mesafesinde de çiziliyor; şerit parlaklığı 0,26; zemin tanesi daha kontrastlı.
- Doğrulandı: Top 13/13 (yeni: 30 m/s yan ve uzun top sınırda kalıyor), hareket 25/25. Kare süresi p95 6,9 ms (önce 2,96; çim katmanları daha uzağa çiziliyor), 16,7 ms bütçenin içinde. Oyun kolu gerçek cihazla denenmedi.
- Açık karar: Oyuncu görünüm/hareket gerçekçiliği — kaynak modelin yalnızca walk/run klibi var; FIFA düzeyi hareket kaydı (mocap) animasyon seti gerektiriyor.

### 9 Kasım 2026 — Pişirilmiş çim dokusu, kutu ağ, sağlam saha sınırı

- Kullanıcı geri bildirimi: Top düz kenardan/köşeden çıkıyor; çim hâlâ kötü; ağ düz; grafik daha iyi olmalı; mobil sonra; testler zaman kaybettiriyor.
- Düzeltildi: Topu tutan duvarlar 2 m kalın, 8 m yüksek (ince duvardan itilen top öbür yana çözülüyordu); oyun alanı dışındaki top başlangıca döner.
- Eklendi: `tools/bake_turf.py` — Blender'da 11 000 modellenmiş yaprak (0,5 m karo, kenar sarmalı, dikişsiz) yukarıdan render: `game/assets/turf/turf_albedo.png` (yaprak gölgeli renk) ve `turf_normal.png`. Zemin ve yakın yaprak katmanları bu dokuyu kullanıyor; biçme şeritleri karonun 180° döndürülmesiyle (yapraklar gerçekten ters yatıyor) ve bakış açısına bağlı parlaklıkla oluşuyor. Gürültü tabanlı renk/tane kaldırıldı. Yakın yaprak katmanları artık yalnızca 5–14 m'de.
- Değişti: Kutu ağ — üst kısım 2,44 → 2,2 m ile geriye gidiyor, arka dikey destekler; ağ ortada sarkar ve rüzgârda dalgalanır; ip 5 mm.
- Mobil: Renderer otomatik "mobile", düşük kalite profili hazır (5 çim katmanı, SSAO yok, 2 gölge bölmesi, %80 çözünürlük); dokunmatik kontrol yok. Kullanıcı mobili sonraya bıraktı.
- Doğrulama: [Genel görüntü](../evidence/m01/01_idle_rear.png). Son çim tonu düzeltmesinden sonra test/görüntü alınmadı (kullanıcı isteğiyle tekrar testler durduruldu).
- Açık: Oyuncu görünüm/hareket gerçekçiliği için animasyon kaynağı kararı (Mixamo veya CC0).

### 9 Kasım 2026 — CC0 animasyon kütüphanesi (yeniden hedefleme)

- Kullanıcı kararı: Oyuncu hareketi için CC0 kütüphane; indirme izni verildi.
- Eklendi: [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html) Standard (CC0, 14,5 MB, Godot Asset Store). Orijinal zip ve lisans `.source/animations/ual1/`; oyun kopyası `game/assets/animations/ual_standard.glb` + `LICENSE_UAL.txt`. Ücretsiz sürümde vuruş yok.
- Eklendi: Godot insan profiline kemik eşlemeleri (`footballer_bone_map.tres`, `ual_bone_map.tres`); her iki GLB içe aktarımda yeniden hedefleniyor (T-poz dinlenme düzeltmesi, eksen eşitleme, kalça yüksekliğine göre konum). İskelet artık `GeneralSkeleton`, kemikler profil adlarıyla (LeftToes, UpperChest...). Kütüphane AnimationLibrary olarak içe aktarılıyor; Godot "_Loop" ekini siliyor.
- Değişti: `locomotion.gd` — yapay idle ve kaynak walk/run kaldırıldı; Idle + Walk/Jog/Sprint karışımı. Karışım konumu doğrudan hız (m/s); her klip kendi ölçülen zemin hızında tepe yapar. Ölçüm (bu iskelette, basan parmak kemiğinin kalçaya göre geriye kayma hızı): Walk 0,98, Jog 5,28, Sprint 8,06 m/s; sol ayak basma fazlarına göre başlangıç hizalı. Kramponlar iskelet ölçeğinden bağımsız bağlanıyor.
- Doğrulama: Tek görüntü ([yürüyüş](../evidence/m01/04_walk.png), [duruş](../evidence/m01/closeup/kit_front.png)). Ayak kayması ve hareket testleri yeni kliplerle çalıştırılmadı.
- Açık: Duruş pozu biraz kambur; oyuncu koşu hızı (4,5) jog klibinin altında, sprint için ayrı tuş henüz yok; vuruş animasyonu yok.

### 9 Kasım 2026 — FIFA tarzı hız, dik duruş, mat çim, TAA

- Kullanıcı geri bildirimi: Duruş kötü, oyuncu yavaş, çim iyi değil.
- Değişti: Tam çubuk/WASD jog 5,3 m/s, Shift/RT sprint 8,0 m/s (klip zemin hızlarıyla aynı); ivme 9, fren 14 m/s². Kısmi çubuk yürür.
- Eklendi: body_balance dik duruş düzeltmesi (göğüs -6°, boyun -14°); aktarılan kliplerde gövde çökük, baş aşağıdaydı.
- Değişti: Çim mat (pürüzlülük 0,97, specular 0,12, normal derinliği 0,55) — alçak güneşte şeritler soluk bej parlıyordu; şerit parlaklığı 0,08; yakın yaprak katmanı 4–9 m. TAA ve debanding açık.
- Doğrulama: Tek görüntü ([yandan](../evidence/m01/03_idle_side.png), [önden](../evidence/m01/closeup/kit_front.png)). Test koşturulmadı.

### 9 Kasım 2026 — Omuz/kol duruşu

- Kullanıcı geri bildirimi: Omuzlar geride; beklenti FIFA ile rekabet edecek kalite.
- Düzeltildi: Göğüs geri yatırma kaldırıldı (omuzları geri çekiyordu). Asıl neden: yeniden hedeflemede dinlenme pozu düzeltmesi varsayılan olarak 15°'nin altındaki sapmaları bırakıyordu; A-pozlu modelin kolları referansın gerisinde kalıyordu. Eşik iki içe aktarımda 1°. [Yandan](../evidence/m01/closeup/kit_side.png).
- Dürüst sınır: Kaynak model (AI tabanlı CC0 gövde) ve 4 klipli ücretsiz set FIFA düzeyinin tavanı değil; daha iyi karakter ve futbol hareket kaydı gerekiyor.

### 9 Kasım 2026 — Yeni futbolcu: MakeHuman (CC0) + MPFB2

- Kullanıcı kararı: Karakteri baştan yap; üç indirme onaylandı.
- İndirildi (`.source/`, Git dışı): MPFB 2.0.18 (extensions.blender.org, GPLv3, yalnızca araç, oyuna girmez; `tools/cache/blender_profile` içindeki ayrı Blender profiline kuruldu, kullanıcının Blender ayarları değişmedi); `makehuman_system_assets_cc0.zip` (CC0, 268 MB); CMU mocap Subject 10 futbol vuruşu BVH 10_01–10_06 (github.com/meshula/cmu-mocap; ticari kullanım serbest — "The data used in this project was obtained from mocap.cs.cmu.edu."). Vuruş klipleri henüz bağlanmadı.
- Eklendi: `tools/build_footballer.py` — atletik erkek fenotip (1,79 m), genç cilt, göz/kaş/kirpik/kısa saç, game_engine iskeleti. Forma ve şort ayrı kumaş: tişört+kot takımı bölündü, kot diz üstünden kesildi. Çorap = baldır derisinin 5 mm dışarı itilmiş kopyası (bacakla birebir deforme olur). Kramponlar her ayağın ölçüsüne göre ölçeklenip ayak/parmak kemiklerine iskinlendi (burun parmakla bükülür). Kumaş altındaki gövde ve botlardaki ayaklar maskeli. Çıktı `game/assets/characters/footballer_mh.glb`.
- Düzeltildi: MPFB "feet_on_ground" yalnızca mesh'i kaldırıyordu; iskelet 0,9 m aşağıda kalıp Godot'da iskinlemeyi bozuyordu. Karakter orijinde kurulup iskeletle birlikte yere indiriliyor.
- Değişti: `locomotion.gd` — forma shader'ı ve çalışma anı krampon bağlama kaldırıldı; `_dress()` forma/şort/çorap renklerini malzemelere uygular, saç kartlarına alfa hash, diğerlerine opak. Model klipsizse AnimationPlayer oluşturulur. Baş düzeltmesi -6°.
- Emekli (dosyalar kaynak/karşılaştırma için duruyor, oyun kullanmıyor): `footballer.glb`, `football_kit.gdshader`, `prepare_character.mjs`, `footballer_bone_map.tres`.
- Doğrulama: Görüntüler ([önden](../evidence/m01/closeup/kit_front.png), [yandan](../evidence/m01/closeup/kit_side.png), [krampon](../evidence/m01/closeup/boots_front.png), [oyun kamerası](../evidence/m01/01_idle_rear.png)). Test koşturulmadı.
- Sıradaki: CMU vuruş kayıtlarını iskelete aktarıp şut (M02).

