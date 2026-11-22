// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/local_store.dart';

final languageProvider = StateProvider<String>((ref) {
  final saved =
      ref.read(localStoreProvider).read('language.v1')?['code'] as String?;
  // ignore: deprecated_member_use
  ref.listenSelf(
      (previous, next) => persist(ref, 'language.v1', {'code': next}));
  return ['en', 'af', 'zu'].contains(saved) ? saved! : 'en';
});
const languageNames = {'en': 'English', 'af': 'Afrikaans', 'zu': 'isiZulu'};
const _words = <String, (String, String)>{
  'Preferences': ('Voorkeure', 'Okuncamelayo'),
  'Settings at a glance': (
    'Instellings in ’n oogopslag',
    'Izilungiselelo ngokubuka nje'
  ),
  'All on': ('Alles aan', 'Konke kuvuliwe'),
  'Some on': ('Sommige aan', 'Okunye kuvuliwe'),
  'Off': ('Af', 'Kuvaliwe'),
  'Help & privacy': ('Hulp en privaatheid', 'Usizo nobumfihlo'),
  'Delivery and order status changes.': (
    'Aflewerings- en bestelstatusveranderinge.',
    'Izinguquko zesimo se-oda nokulethwa.'
  ),
  'Request reviews, quotations and progress.': (
    'Versoekhersienings, kwotasies en vordering.',
    'Ukubuyekezwa kwezicelo, izilinganiso nokuqhubeka.'
  ),
  'Replies and changes to support tickets.': (
    'Antwoorde en veranderinge aan ondersteuningsnavrae.',
    'Izimpendulo nezinguquko ezicelweni zosizo.'
  ),
  'These controls affect in-app updates on this device.': (
    'Hierdie instellings beheer opdaterings in die toepassing op hierdie toestel.',
    'Lezi zilawuli zithinta izibuyekezo zohlelo kule divayisi.'
  ),
  'Prototype · demo data only': (
    'Prototipe · slegs demodata',
    'Uhlelo lokuhlola · idatha yesivivinyo kuphela'
  ),
  'Available languages': ('Beskikbare tale', 'Izilimi ezitholakalayo'),
  'Selected': ('Gekies', 'Kukhethiwe'),
  'Language preview': ('Taalvoorskou', 'Ukubuka ulimi'),
  'Sample language preview': (
    'Plaaslike gunstelinge, by jou deur afgelewer.',
    'Okuthandwayo kwasendaweni kulethwa emnyango wakho.'
  ),
  'Choose your preferred payment method': (
    'Kies jou voorkeurbetaalmetode',
    'Khetha indlela yokukhokha oyithandayo'
  ),
  'Card payment simulation at checkout.': (
    'Kaartbetalingsimulasie by betaalpunt.',
    'Isivivinyo sokukhokha ngekhadi lapho ukhokha.'
  ),
  'Bank transfer simulation at checkout.': (
    'Bankoorplasing-simulasie by betaalpunt.',
    'Isivivinyo sokudlulisa imali yasebhange lapho ukhokha.'
  ),
  'Wallet payment simulation at checkout.': (
    'Beursiebetalingsimulasie by betaalpunt.',
    'Isivivinyo sokukhokha ngesikhwama lapho ukhokha.'
  ),
  'Selected payment method': (
    'Gekose betaalmetode',
    'Indlela yokukhokha ekhethiwe'
  ),
  'Light mode is on': ('Ligmodus is aan', 'Imodi ekhanyayo ivuliwe'),
  'The Gijima Mfana light theme keeps the app bright and uses emerald green and charcoal throughout.':
      (
    'Die Gijima Mfana-ligtema hou die toepassing helder met smaraggroen en houtskoolgrys.',
    'Itimu ekhanyayo ye-Gijima Mfana igcina uhlelo lukhanya, isebenzisa okuluhlaza okwesimaragidu nomnyama ompunga.'
  ),
  'Brand colours': ('Handelsmerkkleure', 'Imibala yomkhiqizo'),
  'Emerald': ('Smaraggroen', 'Okuluhlaza kwesimaragidu'),
  'Charcoal': ('Houtskoolgrys', 'Omnyama ompunga'),
  'Mint': ('Munt', 'Umbala we-mint'),
  'Gijima Mfana · local shopping': (
    'Gijima Mfana · plaaslike inkopies',
    'Gijima Mfana · ukuthenga kwasendaweni'
  ),
  'This customer app is a prototype. The information below explains the demo behaviour.':
      (
    'Hierdie kliënttoepassing is ’n prototipe. Die inligting hieronder verduidelik die demowerking.',
    'Lolu hlelo lwamakhasimende luyisivivinyo. Imininingwane engezansi ichaza indlela olusebenza ngayo.'
  ),
  'Prototype & demo data': (
    'Prototipe en demodata',
    'Uhlelo lokuhlola nedatha yesivivinyo'
  ),
  'Profile details, preferences, requests and orders use sample data and may be saved on this device.':
      (
    'Profielbesonderhede, voorkeure, versoeke en bestellings gebruik voorbeelddata en kan op hierdie toestel gestoor word.',
    'Imininingwane yephrofayela, izilungiselelo, izicelo nama-oda kusebenzisa idatha yesampula futhi kungagcinwa kule divayisi.'
  ),
  'Demo payments': ('Demobetalings', 'Izinkokhelo zesivivinyo'),
  'Payment choices and outcomes are simulated. The app does not collect or store real card or bank credentials.':
      (
    'Betaalkeuses en -uitkomste word gesimuleer. Die toepassing samel of stoor nie regte kaart- of bankbesonderhede nie.',
    'Izindlela nemiphumela yokukhokha kuyalingiswa. Uhlelo aluqoqi noma lugcine imininingwane yangempela yekhadi noma yasebhange.'
  ),
  'Shops and images': ('Winkels en beelde', 'Izitolo nezithombe'),
  'KFC and McDonald’s are illustrative demo listings. No partnership or availability is implied; photography is illustrative.':
      (
    'KFC en McDonald’s is voorbeeldinskrywings. Geen vennootskap of beskikbaarheid word geïmpliseer nie; foto’s is slegs illustratief.',
    'I-KFC ne-McDonald’s yizibonelo kuphela. Akusho ukuthi kunobambiswano noma ukuthi ziyatholakala; izithombe ziyizibonelo.'
  ),
  'Service terms': ('Diensvoorwaardes', 'Imigomo yesevisi'),
  'Full service terms will be supplied before launch.': (
    'Volledige diensvoorwaardes sal voor bekendstelling verskaf word.',
    'Imigomo egcwele yesevisi izonikezwa ngaphambi kokwethulwa.'
  ),
  'Light · Gijima Mfana': ('Lig · Gijima Mfana', 'Ukukhanya · Gijima Mfana'),
  'Total requests': ('Totale versoeke', 'Izicelo sezizonke'),
  'In progress': ('Aan die gang', 'Kuyaqhubeka'),
  'Action needed': ('Aksie nodig', 'Kudingeka isenzo'),
  'Complete': ('Voltooi', 'Kuqediwe'),
  'Start a request': ('Begin ’n versoek', 'Qala isicelo'),
  'Start shopping request': (
    'Begin ’n inkopieversoek',
    'Qala isicelo sokuthengelwa'
  ),
  'Get collection quote': (
    'Kry ’n afhaal-kwotasie',
    'Thola isilinganiso sokulanda'
  ),
  'requests shown': ('versoeke gewys', 'izicelo ezibonisiwe'),
  'Requests refreshed': ('Versoeke verfris', 'Izicelo zibuyekeziwe'),
  'Refresh requests': ('Verfris versoeke', 'Vuselela izicelo'),
  'No requests match this filter': (
    'Geen versoeke pas by hierdie filter nie',
    'Azikho izicelo ezihambisana nalesi sihlungi'
  ),
  'No requests yet': ('Nog geen versoeke nie', 'Azikho izicelo okwamanje'),
  'Choose another status to see your requests.': (
    'Kies ’n ander status om jou versoeke te sien.',
    'Khetha esinye isimo ukuze ubone izicelo zakho.'
  ),
  'Start a personal shopping or collection request above.': (
    'Begin hierbo ’n persoonlike inkopie- of afhaalversoek.',
    'Qala isicelo sokuthengelwa noma sokulanda ngenhla.'
  ),
  'Required details complete': (
    'Vereiste besonderhede voltooi',
    'Imininingwane edingekayo iphelele'
  ),
  'Complete the required details to send your request.': (
    'Voltooi die vereiste besonderhede om jou versoek te stuur.',
    'Gcwalisa imininingwane edingekayo ukuze uthumele isicelo.'
  ),
  'Request details': ('Versoekbesonderhede', 'Imininingwane yesicelo'),
  'Tell us what needs to be collected and delivered.': (
    'Vertel ons wat afgehaal en afgelewer moet word.',
    'Sitshele ukuthi yini okufanele ilandwe futhi ilethwe.'
  ),
  'Describe the item and where you would like us to look.': (
    'Beskryf die item en waar ons daarna moet soek.',
    'Chaza into nendawo ongathanda siyibheke kuyo.'
  ),
  'A photo can help identify the item you need.': (
    '’n Foto kan help om die item te identifiseer.',
    'Isithombe singasiza ukukhomba into oyidingayo.'
  ),
  'Current step': ('Huidige stap', 'Isinyathelo samanje'),
  'Upcoming': ('Volgende', 'Okuzayo'),
  'Closed': ('Gesluit', 'Kuvaliwe'),
  'Selected reference photo': (
    'Geselekteerde verwysingsfoto',
    'Isithombe esikhethiwe esiyisibonelo'
  ),
  'Description': ('Beskrywing', 'Incazelo'),
  'Business': ('Besigheid', 'Ibhizinisi'),
  'Item budget': ('Itembegroting', 'Isabelomali sento'),
  'Shopping & account': ('Inkopies en rekening', 'Ukuthenga ne-akhawunti'),
  'No delivery address saved': (
    'Geen afleweringsadres gestoor nie',
    'Alikho ikheli lokulethwa eligciniwe'
  ),
  'Order status': ('Bestelstatus', 'Isimo se-oda'),
  'Total orders': ('Totale bestellings', 'Ama-oda esewonke'),
  'Refresh orders': ('Verfris bestellings', 'Vuselela ama-oda'),
  'Orders refreshed': ('Bestellings verfris', 'Ama-oda avuselelwe'),
  'Type': ('Tipe', 'Uhlobo'),
  'Sort by': ('Sorteer volgens', 'Hlunga nge-'),
  'All types': ('Alle tipes', 'Zonke izinhlobo'),
  'Newest': ('Nuutste', 'Okusha kakhulu'),
  'Oldest': ('Oudste', 'Okudala kakhulu'),
  'Highest total': ('Hoogste totaal', 'Inani eliphezulu kakhulu'),
  'No orders match these filters': (
    'Geen bestellings pas by hierdie filters nie',
    'Awekho ama-oda ahambisana nalezi zihlungi'
  ),
  'No orders yet': ('Nog geen bestellings nie', 'Awekho ama-oda okwamanje'),
  'Try another status or order type.': (
    'Probeer ’n ander status of bestellingstipe.',
    'Zama esinye isimo noma uhlobo lwe-oda.'
  ),
  'Shop local or request a personal shop and delivery.': (
    'Koop plaaslik of versoek persoonlike inkopies en aflewering.',
    'Thenga endaweni noma ucele ukuthengelwa nokulethwa.'
  ),
  'Browse shops': ('Blaai deur winkels', 'Buka izitolo'),
  'Make a request': ('Dien ’n versoek in', 'Thumela isicelo'),
  'Order progress': ('Bestelvordering', 'Ukuqhubeka kwe-oda'),
  'Collection': ('Afhaal', 'Ukulanda'),
  'Reference': ('Verwysing', 'Inombolo yesithenjwa'),
  'Recipient': ('Ontvanger', 'Umamukeli'),
  'Collection time': ('Afhaaltyd', 'Isikhathi sokulanda'),
  'Instructions': ('Instruksies', 'Imiyalelo'),
  'simulated': ('gesimuleer', 'okuyisivivinyo'),
  'Simulated refund approved': (
    'Gesimuleerde terugbetaling goedgekeur',
    'Ukubuyiselwa kwemali kwesivivinyo kuvunyiwe'
  ),
  'Settings': ('Instellings', 'Izilungiselelo'),
  'Edit profile': ('Wysig profiel', 'Hlela iphrofayela'),
  'Hello': ('Hallo', 'Sawubona'),
  'Demo profile · saved on this device': (
    'Demoprofiel · op hierdie toestel gestoor',
    'Iphrofayela yesivivinyo · igcinwe kule divayisi'
  ),
  'View your order history': (
    'Bekyk jou bestelgeskiedenis',
    'Buka umlando wama-oda akho'
  ),
  'View your in-app updates': (
    'Bekyk jou opdaterings in die toepassing',
    'Buka izaziso zakho ohlelweni'
  ),
  'Language, payments and notifications': (
    'Taal, betalings en kennisgewings',
    'Ulimi, izinkokhelo nezaziso'
  ),
  'Make it yours': ('Maak dit joune', 'Kwenze kube ngokwakho'),
  'Your demo profile is saved on this device.': (
    'Jou demoprofiel word op hierdie toestel gestoor.',
    'Iphrofayela yakho yesivivinyo igcinwe kule divayisi.'
  ),
  'Display name': ('Vertoonnaam', 'Igama eliboniswayo'),
  'Please enter a display name': (
    'Voer asseblief ’n vertoonnaam in',
    'Sicela ufake igama eliboniswayo'
  ),
  'Your preferences': ('Jou voorkeure', 'Okuncamelayo'),
  'In-app notifications': (
    'Kennisgewings in die toepassing',
    'Izaziso zohlelo'
  ),
  'Controls new in-app updates on this device.': (
    'Beheer nuwe opdaterings in die toepassing op hierdie toestel.',
    'Lawula izaziso ezintsha zohlelo kule divayisi.'
  ),
  'Order updates': ('Bestelopdaterings', 'Izaziso zama-oda'),
  'Shopping request updates': (
    'Inkopieversoekopdaterings',
    'Izaziso zezicelo zokuthenga'
  ),
  'Support updates': ('Ondersteuningsopdaterings', 'Izaziso zosizo'),
  'Home': ('Tuis', 'Ekhaya'),
  'Categories': ('Kategorieë', 'Izigaba'),
  'Requests': ('Versoeke', 'Izicelo'),
  'Orders': ('Bestellings', 'Ama-oda'),
  'Profile': ('Profiel', 'Iphrofayela'),
  'Shop': ('Koop', 'Thenga'),
  'Personal shopping': ('Persoonlike inkopies', 'Ukuthengelwa'),
  'Collect & deliver': ('Haal af en lewer af', 'Landa bese uletha'),
  'Language': ('Taal', 'Ulimi'),
  'Language preferences': ('Taalvoorkeure', 'Izilungiselelo zolimi'),
  'Deals & offers': ('Aanbiedinge', 'Okukhethekile'),
  'Your orders': ('Jou bestellings', 'Ama-oda akho'),
  'Your requests': ('Jou versoeke', 'Izicelo zakho'),
  'Your tickets': ('Jou navrae', 'Izicelo zakho zosizo'),
  'Your basket': ('Jou mandjie', 'Ubhasikidi wakho'),
  'Search results': ('Soekresultate', 'Imiphumela yokusesha'),
  'Shops': ('Winkels', 'Izitolo'),
  'Products': ('Produkte', 'Imikhiqizo'),
  'View shop': ('Bekyk winkel', 'Buka isitolo'),
  'See all': ('Sien almal', 'Bona konke'),
  'No matches found. Try another product, category or shop.': (
    'Geen resultate nie. Probeer ’n ander produk, kategorie of winkel.',
    'Akukho okutholakele. Zama omunye umkhiqizo, isigaba noma isitolo.'
  ),
  'Your local favourites. A few taps away.': (
    'Jou plaaslike gunstelinge, net ’n paar tikke weg.',
    'Okuthandayo kwasendaweni sekuseduze.'
  ),
  'What do you need today?': (
    'Wat het jy vandag nodig?',
    'Udinga ini namuhla?'
  ),
  'Around your neighbourhood': ('In jou omgewing', 'Eduze nawe'),
  'Recently viewed': ('Onlangs bekyk', 'Okubukwe muva nje'),
  'Popular in Ermelo': ('Gewild in Ermelo', 'Okudumile e-Ermelo'),
  'Something good, from somewhere nearby.': (
    'Iets lekker van naby.',
    'Okuhle okuvela eduze nawe.'
  ),
  'Checkout': ('Betaalpunt', 'Khokha'),
  'Review and confirm': ('Hersien en bevestig', 'Buyekeza futhi uqinisekise'),
  'Your local Mzansi marketplace': (
    'Jou plaaslike Mzansi-mark',
    'Imakethe yakho yaseMzansi'
  ),
  'Add a local favourite before you check out.': (
    'Voeg ’n plaaslike gunsteling by voordat jy betaal.',
    'Faka okuthandayo kwasendaweni ngaphambi kokukhokha.'
  ),
  'Check your delivery details, items and total before payment.': (
    'Gaan jou afleweringsbesonderhede, items en totaal na voordat jy betaal.',
    'Hlola imininingwane yokulethwa, izinto nesamba ngaphambi kokukhokha.'
  ),
  'Order from': ('Bestelling by', 'I-oda livela ku'),
  'Delivery details': ('Afleweringsbesonderhede', 'Imininingwane yokulethwa'),
  'Review order': ('Hersien bestelling', 'Buyekeza i-oda'),
  'Review your order': ('Hersien jou bestelling', 'Buyekeza i-oda lakho'),
  'Choose a payment method': (
    'Kies ’n betaalmetode',
    'Khetha indlela yokukhokha'
  ),
  'Demo payment options': (
    'Demo-betalingsopsies',
    'Izinketho zokukhokha zesivivinyo'
  ),
  'Preview only · no real payment': (
    'Slegs voorskou · geen regte betaling nie',
    'Ukubuka kuqala kuphela · akukho nkokhelo yangempela'
  ),
  'Gate code, unit or helpful directions': (
    'Hek kode, eenheid of nuttige aanwysings',
    'Ikhodi yesango, inombolo yendawo noma izinkomba'
  ),
  'Choose delivery address': (
    'Kies afleweringsadres',
    'Khetha ikheli lokulethwa'
  ),
  'No delivery addresses saved yet.': (
    'Geen afleweringsadresse is nog gestoor nie.',
    'Awekho amakheli okulethwa agciniwe okwamanje.'
  ),
  'Change delivery address': (
    'Verander afleweringsadres',
    'Shintsha ikheli lokulethwa'
  ),
  'Default': ('Verstek', 'Okuzenzakalelayo'),
  'Outside delivery area': (
    'Buite die afleweringsgebied',
    'Ngaphandle kwendawo yokuletha'
  ),
  'Delivery available · Ermelo': (
    'Aflewering beskikbaar · Ermelo',
    'Ukuletha kuyatholakala · Ermelo'
  ),
  'No delivery address chosen.': (
    'Geen afleweringsadres gekies nie.',
    'Alikho ikheli lokulethwa elikhethiwe.'
  ),
  'Choose address': ('Kies adres', 'Khetha ikheli'),
  'Change delivery time': (
    'Verander afleweringstyd',
    'Shintsha isikhathi sokulethwa'
  ),
  'Choose a delivery date': (
    'Kies ’n afleweringsdatum',
    'Khetha usuku lokulethwa'
  ),
  'Choose a delivery time': (
    'Kies ’n afleweringstyd',
    'Khetha isikhathi sokulethwa'
  ),
  'Use LOCAL10 for 10% off items, up to R 50.': (
    'Gebruik LOCAL10 vir 10% afslag op items, tot R 50.',
    'Sebenzisa i-LOCAL10 ukuthola u-10% esaphulelweni, kufika ku-R 50.'
  ),
  'Discount removed': ('Afslag verwyder', 'Isaphulelo sisusiwe'),
  'Update code': ('Werk kode by', 'Buyekeza ikhodi'),
  'LOCAL10 applied': ('LOCAL10 toegepas', 'I-LOCAL10 isetshenzisiwe'),
  'Code not recognised. Try LOCAL10.': (
    'Kode nie herken nie. Probeer LOCAL10.',
    'Ikhodi ayaziwa. Zama i-LOCAL10.'
  ),
  'Courier delivery from your local shop.': (
    'Koerieraflewering vanaf jou plaaslike winkel.',
    'Ukulethwa yisithunywa okuvela esitolo sakini.'
  ),
  'Helps with order support and secure checkout.': (
    'Help met bestellingsondersteuning en veilige betaalpunt.',
    'Kusiza ngokwesekwa kwama-oda nangokukhokha okuphephile.'
  ),
  'Final order review': (
    'Finale bestellingsoorsig',
    'Ukubuyekezwa kokugcina kwe-oda'
  ),
  'Choose a covered Ermelo or Wesselton address.': (
    'Kies ’n adres binne Ermelo of Wesselton.',
    'Khetha ikheli lase-Ermelo noma e-Wesselton.'
  ),
  'Please check the highlighted checkout details.': (
    'Gaan die gemerkte betaalbesonderhede na.',
    'Hlola imininingwane yokukhokha egqanyisiwe.'
  ),
  'Add items to reach the shop minimum': (
    'Voeg items by om die winkel se minimum te bereik',
    'Faka izinto ukuze ufinyelele inani eliphansi lesitolo'
  ),
  'Processing…': ('Verwerk tans…', 'Kuyacutshungulwa…'),
  'Confirm demo payment': (
    'Bevestig demo-betaling',
    'Qinisekisa inkokhelo yesivivinyo'
  ),
  'Total to pay': ('Totaal betaalbaar', 'Isamba esizokhokhwa'),
  'Local shop': ('Plaaslike winkel', 'Isitolo sasendaweni'),
  'Browse local shops': (
    'Blaai deur plaaslike winkels',
    'Buka izitolo zasendaweni'
  ),
  'Shop minimum reached for': (
    'Winkelminimum bereik vir',
    'Kufinyelelwe enanini eliphansi lesitolo se'
  ),
  'Add': ('Voeg by', 'Faka'),
  'to reach the minimum for': (
    'om die minimum te bereik vir',
    'ukuze ufinyelele inani eliphansi le'
  ),
  'Delivery address': ('Afleweringsadres', 'Ikheli lokulethwa'),
  'Manage delivery addresses': (
    'Bestuur afleweringsadresse',
    'Phatha amakheli okulethwa'
  ),
  'Delivery time': ('Afleweringstyd', 'Isikhathi sokulethwa'),
  'As soon as possible': ('So gou moontlik', 'Ngokushesha ngangokunokwenzeka'),
  'Schedule delivery': ('Beplan aflewering', 'Hlela ukulethwa'),
  'Choose delivery date and time': (
    'Kies afleweringsdatum en -tyd',
    'Khetha usuku nesikhathi sokulethwa'
  ),
  'Estimated 25–40 minutes · Demo': (
    'Geskatte 25–40 minute · Demo',
    'Kulinganiselwa imizuzu 25–40 · Idemo'
  ),
  'Choose a date and time': ('Kies ’n datum en tyd', 'Khetha usuku nesikhathi'),
  'Discount code': ('Afslagkode', 'Ikhodi yesaphulelo'),
  'Apply code': ('Pas kode toe', 'Sebenzisa ikhodi'),
  'Subtotal': ('Subtotaal', 'Isamba esingaphansi'),
  'Delivery fee': ('Afleweringsfooi', 'Imali yokulethwa'),
  'Service fee': ('Diensfooi', 'Imali yesevisi'),
  'Discount': ('Afslag', 'Isaphulelo'),
  'Total': ('Totaal', 'Ingqikithi'),
  'Online payment': ('Aanlynbetaling', 'Inkokhelo eku-inthanethi'),
  'Online payment method': (
    'Aanlynbetalingsmetode',
    'Indlela yokukhokha eku-inthanethi'
  ),
  'Your basket is empty.': (
    'Jou mandjie is leeg.',
    'Ubhasikidi wakho awunalutho.'
  ),
  'Continue to checkout': ('Gaan voort na betaalpunt', 'Qhubeka ukhokhe'),
  'Item instructions (optional)': (
    'Produkinstruksies (opsioneel)',
    'Imiyalelo yomkhiqizo (uma ikhona)'
  ),
  'Delivery instructions (optional)': (
    'Afleweringsinstruksies (opsioneel)',
    'Imiyalelo yokulethwa (uma ikhona)'
  ),
  'Simulated payment outcome': (
    'Gesimuleerde betaalresultaat',
    'Umphumela wokukhokha oyisivivinyo'
  ),
  'Successful': ('Suksesvol', 'Kuphumelele'),
  'Pending': ('Hangend', 'Kulindile'),
  'Failed': ('Misluk', 'Kwehlulekile'),
  'Cancelled': ('Gekanselleer', 'Kukhanseliwe'),
  'Card': ('Kaart', 'Ikhadi'),
  'Instant EFT': ('Onmiddellike EFT', 'I-EFT esheshayo'),
  'Digital wallet': ('Digitale beursie', 'Isikhwama sedijithali'),
  'Demo payments only. No card numbers, bank details or real money.': (
    'Slegs demobetalings. Geen kaartnommers, bankbesonderhede of regte geld nie.',
    'Izinkokhelo zesivivinyo kuphela. Awekho amakhadi, imininingwane yasebhange noma imali yangempela.'
  ),
  '10% off your items': (
    '10% afslag op jou items',
    'Thola isaphulelo sika-10% emikhiqizweni'
  ),
  'Copy LOCAL10': ('Kopieer LOCAL10', 'Kopisha i-LOCAL10'),
  'Apply at checkout': ('Pas by betaalpunt toe', 'Sebenzisa lapho ukhokha'),
  'Browse products': ('Blaai deur produkte', 'Buka imikhiqizo'),
  'Local favourites': ('Plaaslike gunstelinge', 'Okuthandwayo kwasendaweni'),
  'Use LOCAL10 at checkout. Up to R 50 off the item subtotal.': (
    'Gebruik LOCAL10 by betaalpunt. Tot R 50 afslag op die subtotaal.',
    'Sebenzisa i-LOCAL10 lapho ukhokha. Thola kuze kufike ku-R 50 esaphulelweni.'
  ),
  'Demo offer · Shop orders only · One code per order · Delivery and service fees excluded':
      (
    'Demo-aanbod · Slegs winkelbestellings · Een kode per bestelling · Fooie uitgesluit',
    'Umnikelo wesivivinyo · Ama-oda ezitolo kuphela · Ikhodi eyodwa · Izimali zokuletha nezesevisi azifakiwe'
  ),
  'What can we find for you?': (
    'Wat kan ons vir jou kry?',
    'Yini esingakutholela yona?'
  ),
  'Product name': ('Produknaam', 'Igama lomkhiqizo'),
  'Description and requirements': (
    'Beskrywing en vereistes',
    'Incazelo nezidingo'
  ),
  'Quantity': ('Hoeveelheid', 'Inani'),
  'Preferred business / shopping location': (
    'Voorkeurwinkel / inkopieplek',
    'Isitolo noma indawo oyikhethayo'
  ),
  'Maximum item budget (R)': (
    'Maksimum begroting vir items (R)',
    'Isabelomali esiphezulu semikhiqizo (R)'
  ),
  'Urgency': ('Dringendheid', 'Ukuphuthuma'),
  'Today': ('Vandag', 'Namuhla'),
  'Tomorrow': ('Môre', 'Kusasa'),
  'Whenever works': ('Enige tyd', 'Noma nini'),
  'Add reference photo (optional)': (
    'Voeg verwysingsfoto by (opsioneel)',
    'Faka isithombe esiyisibonelo (uma sikhona)'
  ),
  'Change reference photo': ('Verander verwysingsfoto', 'Shintsha isithombe'),
  'Remove photo': ('Verwyder foto', 'Susa isithombe'),
  'Remove saved photo': (
    'Verwyder gestoorde foto',
    'Susa isithombe esigciniwe'
  ),
  'Reference photo': ('Verwysingsfoto', 'Isithombe esiyisibonelo'),
  'JPEG, PNG or WebP, up to 1 MB. Photos stay on this device.': (
    'JPEG, PNG of WebP, tot 1 MB. Foto’s bly op hierdie toestel.',
    'I-JPEG, PNG noma WebP, kufika ku-1 MB. Izithombe zihlala kule divayisi.'
  ),
  'Submit shopping request': (
    'Dien inkopieversoek in',
    'Thumela isicelo sokuthenga'
  ),
  'Collection details': ('Afhaalbesonderhede', 'Imininingwane yokulanda'),
  'Item / parcel name': ('Item / pakkie se naam', 'Igama lento / iphasela'),
  'Business or sender name': (
    'Besigheid of sender se naam',
    'Igama lesitolo noma lomthumeli'
  ),
  'Collection street and building': (
    'Afhaalstraat en gebou',
    'Umgwaqo nesakhiwo sokulanda'
  ),
  'Collection town': ('Afhaaldorp', 'Idolobha lokulanda'),
  'Order reference / collection code': (
    'Bestelverwysing / afhaalkode',
    'Inombolo ye-oda / ikhodi yokulanda'
  ),
  'Recipient name / demo contact': (
    'Ontvanger se naam / demokontak',
    'Igama lomamukeli / ukuthintana kwesivivinyo'
  ),
  'Preferred collection time': (
    'Voorkeur-afhaaltyd',
    'Isikhathi osithandayo sokulanda'
  ),
  'Manage addresses': ('Bestuur adresse', 'Phatha amakheli'),
  'Additional / handling instructions (optional)': (
    'Bykomende / hanteringsinstruksies (opsioneel)',
    'Eminye imiyalelo yokuphatha (uma ikhona)'
  ),
  'Get delivery quotation': (
    'Kry afleweringskwotasie',
    'Thola isilinganiso sokuletha'
  ),
  'Your quotation': ('Jou kwotasie', 'Isilinganiso sakho'),
  'Item price': ('Itemprys', 'Intengo yomkhiqizo'),
  'Accept quotation': ('Aanvaar kwotasie', 'Yamukela isilinganiso'),
  'Reject quotation': ('Wys kwotasie af', 'Yenqaba isilinganiso'),
  'Continue to simulated payment': (
    'Gaan voort na demobetaling',
    'Qhubeka uye enkokhelweni yesivivinyo'
  ),
  'Track delivery order': (
    'Volg afleweringsbestelling',
    'Landela i-oda lokulethwa'
  ),
  'Request progress': ('Vordering van versoek', 'Inqubekela phambili yesicelo'),
  'Submitted': ('Ingedien', 'Sithunyelwe'),
  'Quotation received': ('Kwotasie ontvang', 'Isilinganiso sitholiwe'),
  'Quote accepted': ('Kwotasie aanvaar', 'Isilinganiso samukelwe'),
  'Quote rejected': ('Kwotasie afgekeur', 'Isilinganiso senqatshiwe'),
  'Payment confirmed': ('Betaling bevestig', 'Inkokhelo iqinisekisiwe'),
  'Courier assigned': ('Koerier toegewys', 'Umthumeli wabelwe'),
  'Item purchased': ('Item gekoop', 'Into ithengiwe'),
  'Delivered': ('Afgelewer', 'Kulethiwe'),
  'Order placed': ('Bestelling geplaas', 'I-oda lifakiwe'),
  'Merchant preparing order': (
    'Winkel berei bestelling voor',
    'Isitolo silungisa i-oda'
  ),
  'Courier collecting order': (
    'Koerier haal bestelling af',
    'Umthumeli ulanda i-oda'
  ),
  'Out for delivery': ('Op pad vir aflewering', 'Lisendleleni yokulethwa'),
  'Items': ('Items', 'Imikhiqizo'),
  'Payment summary': ('Betalingsoorsig', 'Isifinyezo senkokhelo'),
  'Delivery tracking': ('Volg aflewering', 'Landela ukulethwa'),
  'Report an issue / request a refund': (
    'Meld ’n probleem / versoek terugbetaling',
    'Bika inkinga / cela ukubuyiselwa imali'
  ),
  'View original request': (
    'Bekyk oorspronklike versoek',
    'Buka isicelo sokuqala'
  ),
  'Cancel order': ('Kanselleer bestelling', 'Khansela i-oda'),
  'Saved addresses': ('Gestoorde adresse', 'Amakheli agciniwe'),
  'Add address': ('Voeg adres by', 'Faka ikheli'),
  'Edit': ('Wysig', 'Hlela'),
  'Delete': ('Vee uit', 'Susa'),
  'Set default': ('Stel as verstek', 'Beka njengeyokuqala'),
  'Label (Home, Work or Other)': (
    'Etiket (Tuis, Werk of Ander)',
    'Igama (Ekhaya, Emsebenzini noma Okunye)'
  ),
  'Street and building': ('Straat en gebou', 'Umgwaqo nesakhiwo'),
  'Town / area': ('Dorp / gebied', 'Idolobha / indawo'),
  'Postal code': ('Poskode', 'Ikhodi yeposi'),
  'Favourites': ('Gunstelinge', 'Izintandokazi'),
  'Saved businesses': ('Gestoorde winkels', 'Izitolo ezigciniwe'),
  'Saved products': ('Gestoorde produkte', 'Imikhiqizo egciniwe'),
  'Notifications': ('Kennisgewings', 'Izaziso'),
  'Mark all read': ('Merk almal as gelees', 'Maka konke njengokufundiwe'),
  'Refresh updates': ('Verfris opdaterings', 'Vuselela izaziso'),
  'You’re all caught up': ('Jy is heeltemal op datum', 'Usunolwazi lwakamuva'),
  'View orders': ('Bekyk bestellings', 'Buka ama-oda'),
  'All updates marked as read': (
    'Alle opdaterings as gelees gemerk',
    'Zonke izaziso zimakwe njengezifundiwe'
  ),
  'Notification marked as read': (
    'Kennisgewing as gelees gemerk',
    'Isaziso simakwe njengesifundiwe'
  ),
  'Updates refreshed': ('Opdaterings verfris', 'Izaziso zibuyekeziwe'),
  'Just now': ('Zo pas', 'Manje nje'),
  'Order cancelled': ('Bestelling gekanselleer', 'I-oda likhanseliwe'),
  'Any paid demo amount can be reviewed through support.': (
    'Enige betaalde demobedrag kan deur ondersteuning nagegaan word.',
    'Noma iyiphi imali yesivivinyo ekhokhiwe ingabuyekezwa ngosizo.'
  ),
  'Personal shopping request received': (
    'Persoonlike inkopieversoek ontvang',
    'Isicelo sokuthengelwa samukelwe'
  ),
  'Delivery quotation ready': (
    'Afleweringskwotasie gereed',
    'Isilinganiso sokulethwa sesilungile'
  ),
  'Request under review': ('Versoek word nagegaan', 'Isicelo siyabuyekezwa'),
  'Quotation ready': ('Kwotasie gereed', 'Isilinganiso sesilungile'),
  'Request payment': ('Versoekbetaling', 'Inkokhelo yesicelo'),
  'Courier allocation pending': (
    'Koeriertoewysing hangend',
    'Ukuthola umthumeli kusalindile'
  ),
  'Support ticket received': (
    'Ondersteuningsversoek ontvang',
    'Isicelo sosizo samukelwe'
  ),
  'Support resolved': ('Ondersteuning afgehandel', 'Udaba losizo luxazululiwe'),
  'Support under review': (
    'Ondersteuning word nagegaan',
    'Usizo luyabuyekezwa'
  ),
  'App update': ('Toepassingsopdatering', 'Isaziso sohlelo lokusebenza'),
  'Help centre': ('Hulpsentrum', 'Isikhungo sosizo'),
  'Help & support': ('Hulp en ondersteuning', 'Usizo nokusekelwa'),
  'How can we help?': ('Hoe kan ons help?', 'Singakusiza kanjani?'),
  'Frequently asked questions': ('Gereelde vrae', 'Imibuzo evame ukubuzwa'),
  'Find quick answers about local delivery and requests.': (
    'Kry vinnige antwoorde oor plaaslike aflewering en versoeke.',
    'Thola izimpendulo ezisheshayo ngokulethwa kwasendaweni nezicelo.'
  ),
  'Search help topics': ('Soek hulponderwerpe', 'Sesha izihloko zosizo'),
  'No help topics match your search.': (
    'Geen hulponderwerpe pas by jou soektog nie.',
    'Azikho izihloko zosizo ezihambisana nosesho lwakho.'
  ),
  'Add at least five characters.': (
    'Voeg minstens vyf karakters by.',
    'Faka okungenani izinhlamvu ezinhlanu.'
  ),
  'Add at least five characters. Please do not include payment details.': (
    'Voeg minstens vyf karakters by. Moet asseblief nie betalingsbesonderhede insluit nie.',
    'Faka okungenani izinhlamvu ezinhlanu. Ungafaki imininingwane yokukhokha.'
  ),
  'Related order': ('Verwante bestelling', 'I-oda elihlobene'),
  'Choose an order for item, delivery or refund issues.': (
    'Kies ’n bestelling vir item-, aflewerings- of terugbetalingsprobleme.',
    'Khetha i-oda uma kunenkinga yomkhiqizo, yokulethwa noma yokubuyiselwa imali.'
  ),
  'Ticket number': ('Navraag-nommer', 'Inombolo yesicelo'),
  'Copy ticket number': ('Kopieer navraag-nommer', 'Kopisha inombolo yesicelo'),
  'Ticket number copied.': (
    'Navraag-nommer gekopieer.',
    'Inombolo yesicelo ikopishiwe.'
  ),
  'Last updated': ('Laas opgedateer', 'Kugcine ukubuyekezwa'),
  'Ticket progress': ('Vordering van navraag', 'Ukuqhubeka kwesicelo'),
  'Issue summary': ('Probleemopsomming', 'Isifinyezo senkinga'),
  'Refund details': (
    'Terugbetalingbesonderhede',
    'Imininingwane yokubuyiselwa imali'
  ),
  'Demo refund amount': (
    'Demo-terugbetalingsbedrag',
    'Inani lokubuyiselwa lemali yesivivinyo'
  ),
  'Reply saved on this device.': (
    'Antwoord op hierdie toestel gestoor.',
    'Impendulo ilondolozwe kule divayisi.'
  ),
  'Resolve this demo ticket?': (
    'Los hierdie demo-navraag op?',
    'Kuxazululwe lesi sicelo sesivivinyo?'
  ),
  'Start a demo review?': (
    'Begin ’n demo-hersiening?',
    'Qala ukubuyekeza kwesivivinyo?'
  ),
  'This will mark the issue resolved and add a final update to the conversation.':
      (
    'Dit sal die probleem as afgehandel merk en ’n finale opdatering by die gesprek voeg.',
    'Lokhu kuzomaka inkinga njengeyixazululiwe bese kwengeza isibuyekezo sokugcina engxoxweni.'
  ),
  'This will move the ticket to Under review and add an update to the conversation.':
      (
    'Dit sal die navraag na Word hersien skuif en ’n opdatering by die gesprek voeg.',
    'Lokhu kuzohambisa isicelo esigabeni sokubuyekezwa bese kwengeza isibuyekezo engxoxweni.'
  ),
  'Continue': ('Gaan voort', 'Qhubeka'),
  'Ticket marked resolved.': (
    'Navraag as afgehandel gemerk.',
    'Isicelo simakwe njengesixazululiwe.'
  ),
  'Ticket moved to review.': (
    'Navraag na hersiening geskuif.',
    'Isicelo siyabuyekezwa.'
  ),
  'Ticket reopened.': ('Navraag heropen.', 'Isicelo sivulwe kabusha.'),
  'Reopen demo ticket': (
    'Heropen demo-navraag',
    'Vula kabusha isicelo sesivivinyo'
  ),
  'Report another issue': ('Meld nog ’n probleem', 'Bika enye inkinga'),
  'Your conversation updates will appear here.': (
    'Jou gesprekopdaterings sal hier verskyn.',
    'Izibuyekezo zengxoxo yakho zizovela lapha.'
  ),
  'Write a helpful reply…': (
    'Skryf ’n nuttige antwoord…',
    'Bhala impendulo ewusizo…'
  ),
  'Back to support': ('Terug na hulp', 'Buyela kosizo'),
  'This ticket may have been removed from this device.': (
    'Hierdie navraag is dalk van hierdie toestel verwyder.',
    'Lesi sicelo kungenzeka sisusiwe kule divayisi.'
  ),
  'This demo ticket has been reopened and is back under review.': (
    'Hierdie demo-navraag is heropen en word weer nagegaan.',
    'Lesi sicelo sesivivinyo sivulwe kabusha futhi siyabuyekezwa.'
  ),
  'Refund status': ('Terugbetalingstatus', 'Isimo sokubuyiselwa imali'),
  'Conversation': ('Gesprek', 'Ingxoxo'),
  'Updates stay on this device for this prototype.': (
    'Opdaterings bly op hierdie toestel vir hierdie prototipe.',
    'Izibuyekezo zigcinwa kule divayisi kulolu hlelo lwesivivinyo.'
  ),
  'We’re here to help': ('Ons is hier om te help', 'Silapha ukukusiza'),
  'Local support for Ermelo and Wesselton.': (
    'Plaaslike hulp vir Ermelo en Wesselton.',
    'Usizo lwasendaweni e-Ermelo nase-Wesselton.'
  ),
  'DEMO SUPPORT · NO LIVE AGENT': (
    'DEMO-ONDERSTEUNING · GEEN REGSTREEKSE AGENT',
    'USIZO LWESIVIVINYO · AKUKHO MSEBENZI OBukhoma'
  ),
  'Demo delivery coverage: Ermelo and Wesselton. Orders, reviews and refunds here are simulated.':
      (
    'Demo-afleweringsgebied: Ermelo en Wesselton. Bestellings, hersienings en terugbetalings hier is gesimuleer.',
    'Indawo yokuletha yesivivinyo: i-Ermelo ne-Wesselton. Ama-oda, ukubuyekezwa nokubuyiselwa kwemali kuyalingiswa.'
  ),
  'No tickets in this status': (
    'Geen navrae in hierdie status nie',
    'Azikho izicelo ezikulesi simo'
  ),
  'Show all tickets': ('Wys alle navrae', 'Bonisa zonke izicelo'),
  'Please enter a reply': ('Voer asseblief ’n antwoord in', 'Faka impendulo'),
  'support tickets': ('hulpnavrae', 'izicelo zosizo'),
  'Select the related order for this issue': (
    'Kies die verwante bestelling vir hierdie probleem',
    'Khetha i-oda elihlobene nale nkinga'
  ),
  'Submit your requirements, review a quotation, accept it, and simulate online payment. Your request then becomes a tracked delivery order.':
      (
    'Dien jou vereistes in, hersien ’n kwotasie, aanvaar dit en simuleer ’n aanlynbetaling. Jou versoek word dan ’n afleweringsbestelling wat opgespoor kan word.',
    'Thumela okudingayo, ubuyekeze isilinganiso, usamukele bese ulingisa ukukhokha ku-inthanethi. Isicelo sakho siba i-oda lokuletha elingalandelwa.'
  ),
  'Thanks. Your demo ticket has been received. Use the simulation below to review it.':
      (
    'Dankie. Jou demo-navraag is ontvang. Gebruik die simulasie hieronder om dit na te gaan.',
    'Siyabonga. Isicelo sakho sesivivinyo samukelwe. Sebenzisa ukulingisa okungezansi ukuze usibuyekeze.'
  ),
  'We are reviewing your order and issue.': (
    'Ons hersien jou bestelling en probleem.',
    'Sibuyekeza i-oda lakho nenkinga.'
  ),
  'Your demo issue is resolved.': (
    'Jou demo-probleem is afgehandel.',
    'Inkinga yakho yesivivinyo isixazululiwe.'
  ),
  'Open': ('Oop', 'Vuliwe'),
  'Resolved': ('Afgehandel', 'Kuxazululiwe'),
  'Under review': ('Word hersien', 'Siyabuyekezwa'),
  'Support ticket': ('Hulpnavraag', 'Isicelo sosizo'),
  'Buy now': ('Koop nou', 'Thenga manje'),
  'You may also like': ('Jy sal dalk ook hou van', 'Ungase uthande nalokhu'),
  'Special instructions (optional)': (
    'Spesiale instruksies (opsioneel)',
    'Imiyalelo ekhethekile (uma ikhona)'
  ),
  'Discover local shops': (
    'Ontdek plaaslike winkels',
    'Thola izitolo zasendaweni'
  ),
  'Saved shops': ('Gestoorde winkels', 'Izitolo ezigciniwe'),
  'All': ('Almal', 'Konke'),
  'Active': ('Aktief', 'Okwamanje'),
  'Completed': ('Voltooi', 'Okuqediwe'),
  'Groceries': ('Kruideniersware', 'Igrosa'),
  'Restaurants': ('Restaurante', 'Izindawo zokudla'),
  'Fresh produce': ('Vars produkte', 'Imifino nezithelo'),
  'Bakery': ('Bakkery', 'Ibhikawozi'),
  'Convenience': ('Geriefswinkel', 'Izidingo zansuku zonke'),
  'Electronics': ('Elektronika', 'Izinto zobuchwepheshe'),
  'Fashion': ('Klere', 'Imfashini'),
  'Beauty': ('Skoonheid', 'Ubuhle'),
  'Household': ('Huishouding', 'Izinto zasekhaya'),
  'Stationery': ('Skryfbehoeftes', 'Izinto zokubhala'),
  'Cancel': ('Kanselleer', 'Khansela'),
  'Save': ('Stoor', 'Gcina'),
  'Back': ('Terug', 'Buyela emuva'),
  'Clear': ('Vee uit', 'Sula'),
  'Clear filters': ('Vee filters uit', 'Sula izihlungi'),
  'Dismiss': ('Maak toe', 'Vala'),
  'Explore now  →': ('Verken nou  →', 'Bheka manje  →'),
  'Choose your preferred language': (
    'Kies jou voorkeurtaal',
    'Khetha ulimi oluthandayo'
  ),
  'Your choice is saved on this device.': (
    'Jou keuse word op hierdie toestel gestoor.',
    'Okukhethile kugcinwa kule divayisi.'
  ),
  'YOUR ACCOUNT': ('JOU REKENING', 'I-AKHAWUNTI YAKHO'),
  'PREFERENCES & HELP': ('VOORKEURE EN HULP', 'IZILUNGISELELO NOSIZO'),
  'What are you shopping for?': (
    'Waarvoor koop jy vandag?',
    'Uthengani namuhla?'
  ),
  'Choose a category to find your local favourites.': (
    'Kies ’n kategorie vir plaaslike gunstelinge.',
    'Khetha isigaba ukuze uthole okuthandayo kwasendaweni.'
  ),
  'Browse all products': ('Blaai deur alle produkte', 'Buka yonke imikhiqizo'),
  'Search categories': ('Soek kategorieë', 'Sesha izigaba'),
  'Search shops or categories': (
    'Soek winkels of kategorieë',
    'Sesha izitolo noma izigaba'
  ),
  'Find a meal, groceries or your local shop': (
    'Soek etes, kruideniersware of winkels',
    'Sesha ukudla, igrosa noma isitolo'
  ),
  'Save 10% on items with LOCAL10': (
    'Bespaar 10% op items met LOCAL10',
    'Yonga u-10% ngemikhiqizo nge-LOCAL10'
  ),
  'Shop orders, personal shopping and collection deliveries.': (
    'Winkelbestellings, persoonlike inkopies en aflewerings.',
    'Ama-oda ezitolo, ukuthengelwa kanye nokulandwa nokulethwa.'
  ),
  'No orders here yet. Shop local or submit a request to get started.': (
    'Nog geen bestellings nie. Koop plaaslik of dien ’n versoek in.',
    'Awekho ama-oda okwamanje. Thenga endaweni noma thumela isicelo.'
  ),
  'Order': ('Bestelling', 'I-oda'),
  'Order not found on this device.': (
    'Bestelling nie op hierdie toestel gevind nie.',
    'I-oda alitholakali kule divayisi.'
  ),
  'Delivery: As soon as possible': (
    'Aflewering: So gou moontlik',
    'Ukulethwa: Ngokushesha ngangokunokwenzeka'
  ),
  'Resolve / retry demo payment': (
    'Voltooi / probeer demobetaling weer',
    'Qedela / zama inkokhelo yesivivinyo futhi'
  ),
  'Add these items to basket again': (
    'Voeg hierdie items weer by die mandjie',
    'Faka le mikhiqizo kubhasikidi futhi'
  ),
  'Illustrative local route · no GPS or mapping service': (
    'Voorbeeldroete · geen GPS of kaartdiens nie',
    'Umzila oyisibonelo · ayikho i-GPS noma isevisi yamamephu'
  ),
  'Contact courier (demo)': (
    'Kontak koerier (demo)',
    'Thinta umthumeli (idemo)'
  ),
  'Cancel this demo order?': (
    'Kanselleer hierdie demobestelling?',
    'Khansela leli oda lesivivinyo?'
  ),
  'Keep order': ('Hou bestelling', 'Gcina i-oda'),
  'Start a new basket?': ('Begin ’n nuwe mandjie?', 'Qala ubhasikidi omusha?'),
  'Keep basket': ('Hou mandjie', 'Gcina ubhasikidi'),
  'Replace basket': ('Vervang mandjie', 'Shintsha ubhasikidi'),
  'Your address': ('Jou adres', 'Ikheli lakho'),
  'Save a business from its storefront.': (
    'Stoor ’n winkel vanaf sy winkelblad.',
    'Gcina isitolo ekhasini laso.'
  ),
  'Tap a product heart to save it.': (
    'Tik op ’n produk se hart om dit te stoor.',
    'Cindezela inhliziyo yomkhiqizo ukuze uwugcine.'
  ),
  'Choose the default online method for demo payments. No payment credentials are stored.':
      (
    'Kies die verstek-aanlynmetode vir demobetalings. Geen betaalbesonderhede word gestoor nie.',
    'Khetha indlela yokukhokha ezenzakalelayo yesivivinyo. Ayikho imininingwane yokukhokha egcinwayo.'
  ),
  'Continue browsing as a guest': (
    'Blaai verder as gas',
    'Qhubeka ubuka njengesivakashi'
  ),
  'Products you view will appear here.': (
    'Produkte wat jy bekyk, sal hier verskyn.',
    'Imikhiqizo oyibukayo izovela lapha.'
  ),
  'A little closer to home.': (
    '’n Bietjie nader aan die huis.',
    'Kuseduze nasekhaya.'
  ),
  'Browse our illustrative Ermelo marketplace and find your next favourite.': (
    'Verken ons voorbeeldmark in Ermelo.',
    'Buka imakethe yethu eyisibonelo yase-Ermelo.'
  ),
  'No shops found. Try another search or remove the saved filter.': (
    'Geen winkels gevind nie. Probeer weer of verwyder die filter.',
    'Azikho izitolo ezitholakele. Sesha futhi noma susa isihlungi.'
  ),
  'No items match your search in this category.': (
    'Geen items in hierdie kategorie pas by jou soektog nie.',
    'Akukho okufana nosesho lwakho kulesi sigaba.'
  ),
  'No updates yet. Order and request updates appear here.': (
    'Nog geen opdaterings nie. Bestellings en versoeke verskyn hier.',
    'Azikho izaziso okwamanje. Izinguquko zama-oda nezicelo zizovela lapha.'
  ),
  'Where do you deliver?': ('Waar lewer julle af?', 'Niletha kuphi?'),
  'How do requests work?': ('Hoe werk versoeke?', 'Zisebenza kanjani izicelo?'),
  'Report an order issue': ('Meld ’n bestelprobleem', 'Bika inkinga nge-oda'),
  'Related order (optional)': (
    'Verwante bestelling (opsioneel)',
    'I-oda elihlobene (uma likhona)'
  ),
  'General enquiry': ('Algemene navraag', 'Umbuzo ojwayelekile'),
  'Issue type': ('Tipe probleem', 'Uhlobo lwenkinga'),
  'Missing item': ('Ontbrekende item', 'Umkhiqizo ongekho'),
  'Damaged item': ('Beskadigde item', 'Umkhiqizo owonakele'),
  'Refund request': ('Terugbetalingsversoek', 'Isicelo sokubuyiselwa imali'),
  'Delivery problem': ('Afleweringsprobleem', 'Inkinga yokulethwa'),
  'Other': ('Ander', 'Okunye'),
  'What happened?': ('Wat het gebeur?', 'Kwenzekeni?'),
  'Create demo support ticket': (
    'Skep demo-hulpnavraag',
    'Dala isicelo sosizo sesivivinyo'
  ),
  'No support tickets yet.': (
    'Nog geen hulpnavrae nie.',
    'Azikho izicelo zosizo okwamanje.'
  ),
  'Ticket not found.': ('Navraag nie gevind nie.', 'Isicelo asitholakali.'),
  'View related order': ('Bekyk verwante bestelling', 'Buka i-oda elihlobene'),
  'Add a reply': ('Voeg ’n antwoord by', 'Faka impendulo'),
  'Send local reply': (
    'Stuur plaaslike antwoord',
    'Thumela impendulo kule divayisi'
  ),
  'Demo delivery region: Ermelo and Wesselton. Use fictional details for this prototype.':
      (
    'Demo-afleweringsgebied: Ermelo en Wesselton. Gebruik fiktiewe besonderhede.',
    'Indawo yesivivinyo: i-Ermelo ne-Wesselton. Sebenzisa imininingwane eyisibonelo.'
  ),
  'No addresses saved. Add one to arrange delivery.': (
    'Geen adresse gestoor nie. Voeg een by vir aflewering.',
    'Awekho amakheli agciniwe. Faka ikheli lokulethwa.'
  ),
  'Addresses outside Ermelo/Wesselton can be saved but cannot be used for delivery.':
      (
    'Adresse buite Ermelo/Wesselton kan gestoor word, maar is nie beskikbaar vir aflewering nie.',
    'Amakheli angaphandle kwe-Ermelo/Wesselton angagcinwa kodwa awatholakali ukulethwa.'
  ),
  'Simulate online payment': (
    'Simuleer aanlynbetaling',
    'Lingisa inkokhelo eku-inthanethi'
  ),
  'Simulate payment': ('Simuleer betaling', 'Lingisa inkokhelo'),
  'Search this shop': ('Soek hierdie winkel', 'Sesha kulesi sitolo'),
  'Save business': ('Stoor winkel', 'Londoloza isitolo'),
  'Unsave business': (
    'Verwyder gestoorde winkel',
    'Susa isitolo esilondoloziwe'
  ),
  'Shop removed from favourites': (
    'Winkel uit gunstelinge verwyder',
    'Isitolo sisusiwe kokuthandwayo'
  ),
  'Shop saved to favourites': (
    'Winkel by gunstelinge gestoor',
    'Isitolo sigcinwe kokuthandwayo'
  ),
  'LOCAL SHOP · ERMELO': (
    'PLAASLIKE WINKEL · ERMELO',
    'ISITOLO SASENDAWENI · ERMELO'
  ),
  'Open for simulated orders · 25–40 min delivery': (
    'Oop vir gesimuleerde bestellings · 25–40 min aflewering',
    'Kuvulekele ama-oda esivivinyo · ukulethwa ngemizuzu engu-25–40'
  ),
  'Demo address': ('Demo-adres', 'Ikheli lesivivinyo'),
  'Demo hours': ('Demo-ure', 'Amahora esivivinyo'),
  'Delivery': ('Aflewering', 'Ukulethwa'),
  'Minimum items': ('Minimum items', 'Inani elincane lezinto'),
  'Fictional rating': ('Fiktiewe gradering', 'Isilinganiso sesibonelo'),
  '25–40 min': ('25–40 min', 'Imizuzu engu-25–40'),
  'Popular at this shop': (
    'Gewild by hierdie winkel',
    'Okuthandwayo kulesi sitolo'
  ),
  'Shop the catalogue': ('Blaai deur die katalogus', 'Bheka ikhathalogi'),
  'Price: low to high': (
    'Prys: laag na hoog',
    'Intengo: kusukela ephansi kuye phezulu'
  ),
  'Price: high to low': (
    'Prys: hoog na laag',
    'Intengo: kusukela ephezulu kuye phansi'
  ),
  'demo products found': (
    'demo-produkte gevind',
    'imikhiqizo yesivivinyo itholakele'
  ),
  'No catalogue yet': ('Nog geen katalogus nie', 'Akukho khathalogi okwamanje'),
  'Illustrative local shop': (
    'Illustrasie van ’n plaaslike winkel',
    'Isithombe esimele isitolo sasendaweni'
  ),
  'No matching items': ('Geen passende items nie', 'Azikho izinto ezifanayo'),
  'This shop has no demo products to show yet.': (
    'Hierdie winkel het nog geen demoprodukte om te wys nie.',
    'Lesi sitolo asikabi nayo imikhiqizo yesivivinyo esingayibonisa.'
  ),
  'Save to favourites': ('Stoor by gunstelinge', 'Londoloza kokuthandwayo'),
  'Remove from favourites': ('Verwyder uit gunstelinge', 'Susa kokuthandwayo'),
  '10% off items, up to R 50. Apply at checkout.': (
    '10% afslag op items, tot R 50. Pas toe by betaalpunt.',
    'Isaphulelo sika-10% kuze kufike ku-R 50. Sisebenzise lapho ukhokha.'
  ),
  'Tell us what you need. Review all fees before accepting a quote.': (
    'Vertel ons wat jy nodig het. Hersien alle fooie voor jy aanvaar.',
    'Sitshele okudingayo. Bheka zonke izindleko ngaphambi kokwamukela.'
  ),
  'Ask us to find an item that is not in the catalogue.': (
    'Vra ons om ’n item buite die katalogus te vind.',
    'Sicele ukuthi sikutholele into engekho ohlwini.'
  ),
  'Already arranged an order? Get a local collection quote.': (
    'Reeds bestel? Kry ’n kwotasie vir plaaslike afhaal.',
    'Usuvele ufakile i-oda? Thola isilinganiso sokulanda.'
  ),
  'Your saved requests and quotations will appear here.': (
    'Jou versoeke en kwotasies sal hier verskyn.',
    'Izicelo nezilinganiso zakho zizovela lapha.'
  ),
  'Use fictional demo details. No courier will be dispatched.': (
    'Gebruik fiktiewe demobesonderhede. Geen koerier word uitgestuur nie.',
    'Sebenzisa imininingwane yesivivinyo. Akukho mthumeli ozothunyelwa.'
  ),
  'Request': ('Versoek', 'Isicelo'),
  'Request not found on this device.': (
    'Versoek nie op hierdie toestel gevind nie.',
    'Isicelo asitholakali kule divayisi.'
  ),
  'Reference photo could not be displayed.': (
    'Verwysingsfoto kon nie vertoon word nie.',
    'Isithombe asikwazanga ukuboniswa.'
  ),
  'Quoted item price covers the full requested quantity.': (
    'Die gekwoteerde itemprys dek die totale hoeveelheid.',
    'Intengo elinganisiwe ihlanganisa lonke inani eliceliwe.'
  ),
  'Illustrative local quote. No real merchant was contacted.': (
    'Voorbeeldkwotasie. Geen regte handelaar is gekontak nie.',
    'Isilinganiso esiyisibonelo. Asikho isitolo sangempela esithintiwe.'
  ),
  'Your basket is empty. Explore local favourites to get started.': (
    'Jou mandjie is leeg. Verken plaaslike gunstelinge.',
    'Ubhasikidi wakho awunalutho. Buka okuthandwayo kwasendaweni.'
  ),
  'No categories match. Try meals, fresh or home.': (
    'Geen kategorieë pas nie. Probeer kos, vars of huis.',
    'Azikho izigaba ezifanayo. Zama ukudla, okusha noma ikhaya.'
  ),
  'Try LOCAL10: 10% off items, max R 50': (
    'Probeer LOCAL10: 10% afslag op items, maksimum R 50',
    'Zama i-LOCAL10: 10% wesaphulelo, kufika ku-R 50'
  ),
  'Add a note for the shop': (
    'Voeg ’n nota vir die winkel by',
    'Faka inothi lesitolo'
  ),
  'One shop per order': (
    'Een winkel per bestelling',
    'Isitolo esisodwa nge-oda'
  ),
  'Start new basket': ('Begin nuwe mandjie', 'Qala ubhasikidi omusha'),
  'No matching items. Try another search or category.': (
    'Geen items pas nie. Probeer ’n ander soektog of kategorie.',
    'Ayikho imikhiqizo efanayo. Zama olunye usesho noma isigaba.'
  ),
  'Open for simulated orders': (
    'Oop vir demobestellings',
    'Ivulekele ama-oda esivivinyo'
  ),
  'Choose a delivery date and time': (
    'Kies afleweringsdatum en -tyd',
    'Khetha usuku nesikhathi sokulethwa'
  ),
  'Please choose a delivery date and time': (
    'Kies ’n afleweringsdatum en -tyd',
    'Sicela ukhethe usuku nesikhathi sokulethwa'
  ),
  'Please choose at least 30 minutes from now': (
    'Kies minstens 30 minute van nou af',
    'Khetha isikhathi okungenani esiyimizuzu engu-30 ukusuka manje'
  ),
  'Scheduled delivery': ('Beplande aflewering', 'Ukulethwa okuhleliwe'),
  'Estimated delivery: 25–40 minutes · Demo only': (
    'Geskatte aflewering: 25–40 minute · Slegs demo',
    'Isikhathi esilinganisiwe: imizuzu 25–40 · Isivivinyo kuphela'
  ),
  'Demo account · Ermelo': (
    'Demorekening · Ermelo',
    'I-akhawunti yesivivinyo · Ermelo'
  ),
  'Your saved shops and products': (
    'Jou gestoorde winkels en produkte',
    'Izitolo nemikhiqizo yakho egciniwe'
  ),
  'Order and offer updates': (
    'Bestelling- en aanbiedingsnuus',
    'Izaziso zama-oda nokukhethekile'
  ),
  'Demo payment options only': (
    'Slegs demobetalingsopsies',
    'Izindlela zokukhokha zesivivinyo kuphela'
  ),
  'FAQs and mock support': (
    'Algemene vrae en demo-ondersteuning',
    'Imibuzo ejwayelekile nosizo lwesivivinyo'
  ),
  'Read our information': ('Lees ons inligting', 'Funda imininingwane yethu'),
  'Demo session': ('Demosessie', 'Isikhathi sesivivinyo'),
  'Payment preferences': ('Betalingsvoorkeure', 'Izilungiselelo zokukhokha'),
  'Appearance': ('Voorkoms', 'Ukubukeka'),
  'Privacy & terms': ('Privaatheid en voorwaardes', 'Ubumfihlo nemibandela'),
  'Sign out': ('Teken uit', 'Phuma'),
  'Sawubona, Sihle 👋': ('Hallo, Sihle 👋', 'Sawubona, Sihle 👋'),
  'The order will remain in cancelled history. For a paid order, use support to request a simulated refund.':
      (
    'Die bestelling bly in gekanselleerde geskiedenis. Versoek ’n demoterugbetaling by hulp vir ’n betaalde bestelling.',
    'I-oda lizohlala emlandweni okhanseliwe. Uma ukhokhile, cela imbuyiselo yesivivinyo kosizo.'
  ),
  'The demo service covers Ermelo and Wesselton. All tracking, payments and refunds are simulated.':
      (
    'Die demo dek Ermelo en Wesselton. Nasporing, betalings en terugbetalings is gesimuleer.',
    'Isevisi yesivivinyo ihlanganisa i-Ermelo ne-Wesselton. Ukulandelela, ukukhokha nokubuyiselwa kwemali kuyalingiswa.'
  ),
  'This conversation stays on your device. No external ticket, message or refund is sent.':
      (
    'Hierdie gesprek bly op jou toestel. Geen eksterne boodskap of terugbetaling word gestuur nie.',
    'Le ngxoxo ihlala kule divayisi. Akukho mlayezo noma mbuyiselo othunyelwa ngaphandle.'
  ),
  'Add and choose a delivery address': (
    'Voeg ’n afleweringsadres by en kies dit',
    'Faka bese ukhetha ikheli lokulethwa'
  ),
  'Delivery is available in Ermelo and Wesselton only': (
    'Aflewering is slegs in Ermelo en Wesselton beskikbaar',
    'Ukulethwa kutholakala e-Ermelo nase-Wesselton kuphela'
  ),
  'Please complete this field': (
    'Voltooi asseblief hierdie veld',
    'Sicela ugcwalise le nkambu'
  ),
  'Choose a JPEG, PNG or WebP image no larger than 1 MB.': (
    'Kies ’n JPEG-, PNG- of WebP-beeld van hoogstens 1 MB.',
    'Khetha isithombe se-JPEG, PNG noma WebP esingadluli ku-1 MB.'
  ),
  'Please choose a valid JPEG, PNG or WebP image.': (
    'Kies asseblief ’n geldige JPEG-, PNG- of WebP-beeld.',
    'Sicela ukhethe isithombe esivumelekile se-JPEG, PNG noma WebP.'
  ),
  'Could not open the photo picker. Please try again.': (
    'Kon nie die fotokieser oopmaak nie. Probeer weer.',
    'Ayikwazanga ukuvula indawo yezithombe. Zama futhi.'
  ),
  'Please choose a time 30 minutes to 14 days from now': (
    'Kies ’n tyd tussen 30 minute en 14 dae van nou af',
    'Khetha isikhathi esiphakathi kwemizuzu engu-30 nezinsuku ezingu-14'
  ),
  'Delivery must be after the preferred collection time': (
    'Aflewering moet ná die voorkeur-afhaaltyd wees',
    'Ukulethwa kufanele kube ngemva kwesikhathi sokulanda'
  ),
  'Scheduled delivery; updates are simulated.': (
    'Beplande aflewering; opdaterings is gesimuleer.',
    'Ukulethwa okuhleliwe; izaziso ziyalingiswa.'
  ),
  'Demo shops and prices are illustrative; no live merchant availability or affiliation is implied.':
      (
    'Winkels en pryse is voorbeelde; dit dui nie op regstreekse beskikbaarheid of vennootskappe nie.',
    'Izitolo nezintengo ziyizibonelo; azisho ukuthi ziyatholakala noma ukuthi kunobambiswano.'
  ),
  'Sample catalogue, prices and availability. No affiliation with named brands or live merchant ordering.':
      (
    'Voorbeeldkatalogus, pryse en beskikbaarheid. Geen vennootskap of regstreekse bestellings nie.',
    'Uhla lwemikhiqizo, izintengo nokutholakala kuyizibonelo. Akukho budlelwano noma ama-oda angempela.'
  ),
  'Sample prices and photos · no live merchant promotions': (
    'Voorbeeldpryse en foto’s · geen regstreekse aanbiedinge nie',
    'Izintengo nezithombe ziyizibonelo · akukho okunikezwayo kwangempela'
  ),
  'You rejected this quotation. No payment was taken. Submit a new request to change requirements.':
      (
    'Jy het die kwotasie afgekeur. Geen betaling is geneem nie. Dien ’n nuwe versoek in om besonderhede te verander.',
    'Usenqabile lesi silinganiso. Ayikho imali ethathiwe. Thumela isicelo esisha ukushintsha izidingo.'
  ),
  'Payment': ('Betaling', 'Inkokhelo'),
  'Not paid': ('Nie betaal nie', 'Akukhokhiwe'),
  'Explore categories': ('Verken kategorieë', 'Buka izigaba'),
  'Search products and local shops': (
    'Soek produkte en plaaslike winkels',
    'Sesha imikhiqizo nezitolo zasendaweni'
  ),
  'product': ('produk', 'umkhiqizo'),
  'products': ('produkte', 'imikhiqizo'),
  'shop': ('winkel', 'isitolo'),
  'shops': ('winkels', 'izitolo'),
  'Everyday pantry favourites': (
    'Alledaagse koskasgunstelinge',
    'Okuthandwayo kwasekhishini nsuku zonke'
  ),
  'item': ('item', 'umkhiqizo'),
  'items': ('items', 'imikhiqizo'),
  'Popular': ('Gewild', 'Okudumile'),
  'New': ('Nuut', 'Okusha'),
  'Clear search': ('Vee soektog uit', 'Sula usesho'),
  'No categories match your search.': (
    'Geen kategorieë pas by jou soektog nie.',
    'Azikho izigaba ezihambisana nosesho lwakho.'
  ),
  'Try another search or clear it to see everything.': (
    'Probeer ’n ander soektog of vee dit uit om alles te sien.',
    'Zama olunye usesho noma ulusule ukuze ubone konke.'
  ),
  'Meals, burgers & chicken': (
    'Etes, burgers en hoender',
    'Ukudla, amabhega nenkukhu'
  ),
  'Fruit & vegetables': ('Vrugte en groente', 'Izithelo nemifino'),
  'Fresh bread & baked treats': (
    'Vars brood en gebak',
    'Isinkwa esisha namakhekhe'
  ),
  'Quick snacks & essentials': (
    'Vinnige peuselhappies en benodigdhede',
    'Ukudla okulula nezidingo ezibalulekile'
  ),
  'Useful tech & accessories': (
    'Nuttige tegnologie en bykomstighede',
    'Ubuchwepheshe nezinsiza eziwusizo'
  ),
  'Everyday clothing': ('Alledaagse klere', 'Izingubo zansuku zonke'),
  'Personal care favourites': ('Persoonlike versorging', 'Okokuzinakekela'),
  'Essentials for your home': (
    'Benodigdhede vir jou huis',
    'Izidingo zekhaya lakho'
  ),
  'School & office supplies': (
    'Skool- en kantoorbenodigdhede',
    'Izinto zesikole nezehhovisi'
  ),
  'Delivery cancelled': ('Aflewering gekanselleer', 'Ukulethwa kukhanseliwe'),
  'Delivered to your demo address': (
    'By jou demoadres afgelewer',
    'Kulethwe ekhelini lakho lesivivinyo'
  ),
  'Courier allocation follows payment and preparation.': (
    '’n Koerier word ná betaling en voorbereiding toegewys.',
    'Umthumeli wabelwa ngemva kokukhokha nokulungiselela.'
  ),
  'Add photo': ('Voeg foto by', 'Faka isithombe'),
  'Your places': ('Jou plekke', 'Izindawo zakho'),
  'Manage delivery locations and choose where your demo order goes.': (
    'Bestuur afleweringsplekke en kies waar jou demo-bestelling afgelewer word.',
    'Phatha izindawo zokuletha bese ukhetha lapho kuzolethwa khona i-oda lesivivinyo.'
  ),
  'Saved places': ('Gestoorde plekke', 'Izindawo ezigciniwe'),
  'Check delivery coverage': (
    'Kyk na afleweringsdekking',
    'Hlola indawo yokuletha'
  ),
  'Enter a town or four-digit postal code to check the demo area.': (
    'Voer ’n dorp of vier-syfer-poskode in om die demo-area na te gaan.',
    'Faka idolobha noma ikhodi yeposi enezinombolo ezine ukuze uhlole indawo yesivivinyo.'
  ),
  'Town or postal code': ('Dorp of poskode', 'Idolobha noma ikhodi yeposi'),
  'e.g. Ermelo or 2351': ('bv. Ermelo of 2351', 'isib. i-Ermelo noma u-2351'),
  'Check coverage': ('Kyk na dekking', 'Hlola indawo'),
  'Coverage is available for this demo.': (
    'Aflewering is vir hierdie demo beskikbaar.',
    'Ukuletha kuyatholakala kulesi sivivinyo.'
  ),
  'This location is outside the demo area. You can still save it.': (
    'Hierdie plek is buite die demo-area. Jy kan dit steeds stoor.',
    'Le ndawo ingaphandle kwendawo yesivivinyo. Usengayigcina.'
  ),
  'Checked location:': ('Plek nagegaan:', 'Indawo ehloliwe:'),
  'Demo area: Ermelo and Wesselton · postal code 2351.': (
    'Demo-area: Ermelo en Wesselton · poskode 2351.',
    'Indawo yesivivinyo: i-Ermelo ne-Wesselton · ikhodi yeposi 2351.'
  ),
  'Demo area: Ermelo and Wesselton · postal code 2351': (
    'Demo-area: Ermelo en Wesselton · poskode 2351',
    'Indawo yesivivinyo: i-Ermelo ne-Wesselton · ikhodi yeposi 2351'
  ),
  'addresses': ('adresse', 'amakheli'),
  'address': ('adres', 'ikheli'),
  'Add delivery address': ('Voeg afleweringsadres by', 'Faka ikheli lokuletha'),
  'Default address': ('Verstekadres', 'Ikheli eliyinhloko'),
  'Delivery available': ('Aflewering beskikbaar', 'Ukuletha kuyatholakala'),
  'Outside demo area': ('Buite demo-area', 'Ngaphandle kwendawo yesivivinyo'),
  'Estimate · 25–40 min': (
    'Raming · 25–40 min',
    'Isilinganiso · imizuzu 25–40'
  ),
  'Estimate unavailable': (
    'Raming nie beskikbaar nie',
    'Isilinganiso asitholakali'
  ),
  'Demo delivery fee varies by shop': (
    'Demo-afleweringsfooi verskil per winkel',
    'Imali yokuletha yesivivinyo iyahlukahluka ngesitolo'
  ),
  'Demo pin': ('Demo-pen', 'Iphini lesivivinyo'),
  'Illustrative demo map': (
    'Illustratiewe demokaart',
    'Imephu yesivivinyo eyisibonelo'
  ),
  'Saved address': ('Gestoorde adres', 'Ikheli eligciniwe'),
  'Work': ('Werk', 'Emsebenzini'),
  'No delivery addresses yet': (
    'Nog geen afleweringsadresse nie',
    'Awekho amakheli okuletha okwamanje'
  ),
  'Add a place to make checkout quicker. This prototype uses local demo details.':
      (
    'Voeg ’n plek by om afhandeling vinniger te maak. Hierdie prototipe gebruik plaaslike demobesonderhede.',
    'Faka indawo ukuze ukhokhe ngokushesha. Lesi sivivinyo sisebenzisa imininingwane eyisibonelo egcinwe kule divayisi.'
  ),
  'Add your first address': (
    'Voeg jou eerste adres by',
    'Faka ikheli lakho lokuqala'
  ),
  'Address actions': ('Adresaksies', 'Izenzo zekheli'),
  'Edit address': ('Wysig adres', 'Hlela ikheli'),
  'Make default': ('Stel as verstek', 'Beka njengekheli eliyinhloko'),
  'Remove address': ('Verwyder adres', 'Susa ikheli'),
  'Remove this address?': ('Verwyder hierdie adres?', 'Ususe leli kheli?'),
  'You can add it again later. Existing orders keep their saved address.': (
    'Jy kan dit later weer byvoeg. Bestaande bestellings behou hul gestoorde adres.',
    'Ungalifaka futhi kamuva. Ama-oda akhona azogcina ikheli lawo elilondoloziwe.'
  ),
  'Address removed.': ('Adres verwyder.', 'Ikheli lisusiwe.'),
  'Default address updated.': (
    'Verstekadres opgedateer.',
    'Ikheli eliyinhloko libuyekeziwe.'
  ),
  'Close': ('Sluit', 'Vala'),
  'Edit delivery address': ('Wysig afleweringsadres', 'Hlela ikheli lokuletha'),
  'Address details': ('Adresbesonderhede', 'Imininingwane yekheli'),
  'Local example only: 12 Acacia Street, Ermelo, Mpumalanga 2351.': (
    'Slegs ’n plaaslike voorbeeld: 12 Acacia Street, Ermelo, Mpumalanga 2351.',
    'Isibonelo sendawo kuphela: 12 Acacia Street, e-Ermelo, eMpumalanga 2351.'
  ),
  'Address label': ('Adresbenaming', 'Igama lekheli'),
  'e.g. Home or Work': ('bv. Tuis of Werk', 'isib. Ekhaya noma Emsebenzini'),
  'Unit or apartment number': (
    'Eenheid- of woonstelnommer',
    'Inombolo yefulethi'
  ),
  'e.g. Flat 4': ('bv. Woonstel 4', 'isib. Ifulethi 4'),
  'Building or complex name (optional)': (
    'Gebou- of kompleksnaam (opsioneel)',
    'Igama lesakhiwo noma lendawo yokuhlala (uma uthanda)'
  ),
  'e.g. Acacia Court': ('bv. Acacia Court', 'isib. i-Acacia Court'),
  'Street address': ('Straatadres', 'Ikheli lomgwaqo'),
  'e.g. 12 Acacia Street': ('bv. 12 Acacia Street', 'isib. 12 Acacia Street'),
  'Suburb (optional)': (
    'Voorstad (opsioneel)',
    'Indawo yokuhlala (uma uthanda)'
  ),
  'e.g. Ermelo Central': ('bv. Sentraal-Ermelo', 'isib. e-Central Ermelo'),
  'Town / city': ('Dorp / stad', 'Idolobha'),
  'e.g. Ermelo': ('bv. Ermelo', 'isib. i-Ermelo'),
  'Province': ('Provinsie', 'Isifundazwe'),
  'e.g. Mpumalanga': ('bv. Mpumalanga', 'isib. iMpumalanga'),
  'Enter a label such as Home or Work.': (
    'Voer ’n benaming soos Tuis of Werk in.',
    'Faka igama elifana nelithi Ekhaya noma Emsebenzini.'
  ),
  'Enter a street address.': (
    'Voer ’n straatadres in.',
    'Faka ikheli lomgwaqo.'
  ),
  'Enter a town or city.': ('Voer ’n dorp of stad in.', 'Faka idolobha.'),
  'Enter a four-digit South African postal code.': (
    'Voer ’n Suid-Afrikaanse poskode van vier syfers in.',
    'Faka ikhodi yeposi yaseNingizimu Afrika enezinombolo ezine.'
  ),
  'Delivery available for this demo address.': (
    'Aflewering is vir hierdie demo-adres beskikbaar.',
    'Ukuletha kuyatholakala kuleli kheli lesivivinyo.'
  ),
  'Outside the demo area. You can save this address for later.': (
    'Buite die demo-area. Jy kan hierdie adres vir later stoor.',
    'Ngaphandle kwendawo yesivivinyo. Ungaligcina leli kheli ukuze ulisebenzise kamuva.'
  ),
  'Illustrative map pin': (
    'Illustratiewe kaartpen',
    'Iphini lemephu eliyisibonelo'
  ),
  'Choose demo pin': ('Kies demo-pen', 'Khetha iphini lesivivinyo'),
  'This demo pin uses the town only; it does not use live location.': (
    'Hierdie demo-pen gebruik slegs die dorp; dit gebruik nie jou lewendige ligging nie.',
    'Leli phini lesivivinyo lisebenzisa idolobha kuphela; alisebenzisi indawo yakho yangempela.'
  ),
  'Delivery instructions': ('Afleweringsinstruksies', 'Imiyalelo yokuletha'),
  'Directions for driver (optional)': (
    'Aanwysings vir bestuurder (opsioneel)',
    'Imiyalelo yomshayeli (uma uthanda)'
  ),
  'Gate code, landmark or where to leave the order': (
    'Heknommer, baken of waar om die bestelling te los',
    'Ikhodi yesango, uphawu lwendawo noma lapho kushiywa khona i-oda'
  ),
  'Save address': ('Stoor adres', 'Gcina ikheli'),
  'Please complete this field.': (
    'Voltooi asseblief hierdie veld.',
    'Sicela ugcwalise le ngxenye.'
  ),
  'Choose a demo pin location': (
    'Kies ’n demo-penplek',
    'Khetha indawo yephini lesivivinyo'
  ),
  'Town centre': ('Dorpsentrum', 'Enkabeni yedolobha'),
  'Near my street': ('Naby my straat', 'Eduze nomgwaqo wami'),
  'Undo': ('Ontdoen', 'Hlehlisa'),
  'Recent searches': ('Onlangse soektogte', 'Usesho lwakamuva'),
  'Clear history': ('Vee geskiedenis uit', 'Sula umlando'),
  'Your recently viewed items will appear here.': (
    'Items wat jy onlangs bekyk het, sal hier verskyn.',
    'Izinto ozibuke kamuva zizovela lapha.'
  ),
  'Explore local favourites to get started.': (
    'Ontdek plaaslike gunstelinge om te begin.',
    'Hlola okuthandwayo kwasendaweni ukuze uqale.'
  ),
  'Local is lekker.': ('Plaaslik is lekker.', 'Okwasendaweni kumnandi.'),
  'Find Ermelo neighbourhood favourites': (
    'Vind gunstelinge in Ermelo se buurt',
    'Thola okuthandwayo komakhelwane base-Ermelo'
  ),
  'A proper lunch break.': (
    '’n Behoorlike middagete.',
    'Isidlo sasemini esimnandi.'
  ),
  'Peri-peri, pap and flame-grilled favourites': (
    'Peri-peri, pap en gunstelinge van die vlamrooster',
    'I-peri-peri, uphuthu nokuthandwayo okosiwe elangabini'
  ),
  'Fresh for the week.': ('Vars vir die week.', 'Okusha kweviki.'),
  'From local produce to your kitchen': (
    'Van plaaslike varsprodukte tot in jou kombuis',
    'Kusuka emikhiqizweni yasendaweni kuya ekhishini lakho'
  ),
  'Up to R 50 off items with LOCAL10': (
    'Tot R 50 afslag op items met LOCAL10',
    'Kufika ku-R 50 wesaphulelo ngezinto nge-LOCAL10'
  ),
  'Estimated savings': ('Geskatte besparing', 'Imali elinganiselwa ukonga'),
  'Sort local shops': (
    'Sorteer plaaslike winkels',
    'Hlela izitolo zasendaweni'
  ),
  'Recommended': ('Aanbeveel', 'Kunconyiwe'),
  'Top rated': ('Hoogste gradering', 'Ezikalwe kakhulu'),
  'Fastest delivery': ('Vinnigste aflewering', 'Ukulethwa okushesha kakhulu'),
  '25–35 min · Demo': ('25–35 min · Demo', '25–35 imin · Isivivinyo'),
  '30–40 min · Demo': ('30–40 min · Demo', '30–40 imin · Isivivinyo'),
  '35–45 min · Demo': ('35–45 min · Demo', '35–45 imin · Isivivinyo'),
  'Back to top': ('Terug na bo', 'Buyela phezulu'),
  'Everyday favourites': (
    'Alledaagse gunstelinge',
    'Okuthandwayo kwansuku zonke'
  ),
  'We’ll find it for you': ('Ons sal dit vir jou vind', 'Sizokutholela kona'),
  'From A to your door': (
    'Van A tot by jou deur',
    'Sikusukela ku-A kuye ekhaya'
  ),
  'All deals': ('Alle aanbiedinge', 'Konke okunikezwayo'),
  'Search deals, shops or food': (
    'Soek aanbiedinge, winkels of kos',
    'Sesha okunikezwayo, izitolo noma ukudla'
  ),
  'Local shop offers': (
    'Plaaslike winkel-aanbiedinge',
    'Okunikezwa izitolo zasendaweni'
  ),
  'offers': ('aanbiedinge', 'okunikezwayo'),
  'Sample promotions · no live merchant promotions': (
    'Voorbeeldpromosies · geen regstreekse winkelpromosies nie',
    'Izaphulelo zesibonelo · azikho izaphulelo zesitolo ezibukhoma'
  ),
  'Ends 30 Nov 2026': ('Eindig 30 Nov 2026', 'Iphela ngomhlaka-30 Nov 2026'),
  'Your estimated savings': (
    'Jou beraamde besparing',
    'Imali olinganiselwa ukuyonga'
  ),
  'Add items to see your savings. Maximum R 50 at R 500 in items.': (
    'Voeg items by om jou besparing te sien. Maksimum R 50 by R 500 se items.',
    'Faka izinto ukuze ubone ukonga kwakho. Ubuningi buka-R 50 uma unezinto zika-R 500.'
  ),
  'Savings progress · maximum R 50 at R 500 in items.': (
    'Besparingsvordering · maksimum R 50 by R 500 se items.',
    'Ukuqhubeka kokonga · ubuningi buka-R 50 uma unezinto zika-R 500.'
  ),
  'LOCAL10 · 10% off': ('LOCAL10 · 10% afslag', 'LOCAL10 · 10% isephulelo'),
  'LOCAL10 copied': ('LOCAL10 gekopieer', 'I-LOCAL10 ikopishiwe'),
  'Use code LOCAL10 at checkout': (
    'Gebruik kode LOCAL10 by betaalpunt',
    'Sebenzisa ikhodi i-LOCAL10 lapho ukhokha'
  ),
  'Shop minimums vary by store and still apply at checkout.': (
    'Winkelminimums verskil per winkel en geld steeds by betaalpunt.',
    'Inani elincane le-oda liyahluka ngesitolo futhi lisasebenza lapho ukhokha.'
  ),
  'Different shop': ('Ander winkel', 'Esinye isitolo'),
  'Add to basket': ('Voeg by mandjie', 'Faka kubhasikidi'),
  'Added to basket': ('By mandjie gevoeg', 'Kufakwe kubhasikidi'),
  'Your basket has items from another shop. Finish or clear that basket first.':
      (
    'Jou mandjie bevat items van ’n ander winkel. Voltooi of maak eers daardie mandjie leeg.',
    'Ubhasikidi wakho unezinto ezivela kwesinye isitolo. Qedela noma usule lowo bhasikidi kuqala.'
  ),
  'Demo offers use sample data and prices. LOCAL10 is the working checkout code; it takes 10% off items up to R 50. Delivery and service fees are excluded.':
      (
    'Demo-aanbiedinge gebruik voorbeelddata en pryse. LOCAL10 is die werkende betaalkode; dit gee 10% afslag op items tot R 50. Aflewerings- en diensfooie is uitgesluit.',
    'Izipesheli zesivivinyo zisebenzisa idatha nezintengo zesibonelo. I-LOCAL10 iyikhodi esebenza lapho ukhokha; yehlisa u-10% ezintweni kuze kufike ku-R 50. Izindleko zokuletha nezesevisi azifakiwe.'
  ),
  'No deals match your search.': (
    'Geen aanbiedinge pas by jou soektog nie.',
    'Akukho okunikezwayo okufana nosesho lwakho.'
  ),
  'Try another shop or food': (
    'Probeer ’n ander winkel of kos',
    'Zama esinye isitolo noma okunye ukudla'
  ),
};
String tr(BuildContext context, String text) {
  final language = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  final pair = _words[text];
  return pair == null
      ? text
      : language == 'af'
          ? pair.$1
          : language == 'zu'
              ? pair.$2
              : text;
}

class AppText extends StatelessWidget {
  const AppText(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.maxLines,
      this.overflow,
      this.softWrap,
      this.semanticsLabel});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => Text(tr(context, data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel);
}
