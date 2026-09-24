extends RefCounted

# Contents follow Aether HELP.docx. Manual items that are not available in the
# current build are retained and explicitly identified as planned features.

const SECTION_NAMES_IT := [
	"Panoramica e barra", "Settings", "Finestra principale",
	"Nucleo e data", "CCD e trasparenza", "Simulazione",
	"Sole e asse", "Polveri", "Dust Jets",
]
const SECTION_NAMES_EN := [
	"Overview and top bar", "Settings", "Main viewport",
	"Nucleus and date", "CCD and transparency", "Simulation",
	"Sun and spin axis", "Dust", "Dust Jets",
]

const CONTENT_IT := [
"""[font_size=26][color=#45B8CF]AETHER HELP[/color][/font_size]

AETHER permette di configurare una cometa, scaricare le effemeridi da JPL Horizons, costruire un modello delle emissioni di polvere e confrontarlo con un'immagine telescopica.

[font_size=19][color=#B7C7CF]Barra superiore[/color][/font_size]

[img=24x24]res://asset/save_icon.png[/img]  [b]Freccia verso il basso[/b]
Salva un file di configurazione con i parametri impostati per la cometa e i dati dell'immagine caricata per la data corrente.

[img=24x24]res://asset/load_icon.png[/img]  [b]Freccia verso l'alto[/b]
Carica un file di configurazione salvato in precedenza.

[font_size=19][color=#B7C7CF]Procedura consigliata[/color][/font_size]

1. Inserisci cometa, intervallo temporale e step nella scheda Settings.
2. Scarica elementi orbitali ed effemeridi con la lente.
3. Apri Model e configura nucleo, asse, polveri e aree attive.
4. Carica l'immagine CCD, esegui il modello e confronta i risultati.
5. Salva la configurazione, l'immagine o i dati CSV.

[color=#E7B64A][b]Esempio[/b][/color] Cerca 67P, seleziona un intervallo breve con step di 24 ore e completa il modello usando parametri fisici provenienti dalla letteratura o dall'osservazione. L'esempio illustra il flusso operativo e non rappresenta un preset scientifico.""",

"""[font_size=26][color=#45B8CF]Tab Settings[/color][/font_size]

Settings è la schermata iniziale del software. Inserisci il nome o la designazione della cometa e scegli l'intervallo di osservazione. Le date possono essere scritte nel formato gg/mm/aaaa oppure selezionate con [img=22x22]res://asset/Calendar32x32.png[/img].

[b]Step Size (h)[/b] stabilisce l'intervallo tra due righe delle effemeridi. Il manuale prevede valori da 1 a 24 ore; 24 ore corrispondono a uno step giornaliero.

Premendo la lente [img=22x22]res://asset/search_icon.png[/img], AETHER si collega a JPL Horizons e scarica gli elementi orbitali. Questi vengono mostrati nel riquadro [b]Orbital Elements[/b], mentre [b]Ephemeris results[/b] visualizza le effemeridi.

Le caselle di [b]Table Settings[/b] determinano quali dati compaiono nella tabella: coordinate astrometriche, distanza dall'osservatore, angolo subsolare, distanza eliocentrica, angolo di fase, angolo del piano orbitale, anomalia vera, [b]PsAMV[/b] e direzione del moto apparente. PsAMV è l'angolo di posizione della velocità eliocentrica negativa proiettata sul cielo e indica la direzione attesa della coda di polvere.

[b]EXPORT CSV[/b] salva le effemeridi per l'analisi con programmi esterni, per esempio Excel. Dopo il download dei dati passa alla scheda Model.""",

"""[font_size=26][color=#45B8CF]Finestra principale[/color][/font_size]

La finestra principale mostra il modello generato e l'immagine telescopica caricata. Il modello può essere sovrapposto all'immagine con trasparenza regolabile oppure visualizzato su fondo nero.

I comandi sotto la vista permettono di mostrare:

• la griglia di coordinate in gradi decimali;
• la data o l'ora correnti;
• un righello in arcosecondi o chilometri, lungo un sesto del FOV dell'immagine.

[img=24x24]res://asset/32x32_grid.png[/img] attiva la griglia. Il comando [b]Overlays[/b] cambia griglia, data e scala tra bianco e nero, anche nell'immagine salvata.

[font_size=19][color=#B7C7CF]Comandi del mouse e della tastiera[/color][/font_size]

• Tieni premuto il tasto destro del mouse e trascina per ruotare intorno alla cometa.
• Ruota la rotellina verso l'alto per aumentare lo zoom.
• Ruota la rotellina verso il basso per ridurre lo zoom.
• Premi [b]R[/b] per ripristinare la posizione, la scala corretta e la vista geocentrica.

Le sezioni laterali possono essere ridotte con −. Quando tutte le sezioni di una colonna sono chiuse, la vista centrale si espande.

Il pulsante ⛶ nell'angolo della vista apre la modalità a schermo intero dedicata al modello. Premi nuovamente il pulsante, [b]F11[/b] oppure [b]Esc[/b] per ripristinare tutti i pannelli.""",

"""[font_size=26][color=#45B8CF]Nucleus Model e Change Date / Hour[/color][/font_size]

[font_size=19][color=#B7C7CF]Nucleus Model[/color][/font_size]

Il riquadro mostra il nucleo e il suo grado di illuminazione in funzione della geometria di osservazione e della posizione del Sole.

I pulsanti sotto l'anteprima mostrano o nascondono:

[color=#F2E94E]■ direzione del Sole, in giallo[/color]
[color=#45D65A]■ asse di rotazione, in verde[/color]
[color=#32B8E6]■ vettore della velocità apparente (Sky mot PA JPL), in azzurro[/color]

Il pulsante dell'asse verde mostra o nasconde insieme entrambe le metà dell'asse di rotazione. Il pulsante della velocità agisce separatamente dalla direzione del Sole e dall'asse.

Sono disponibili anche la griglia di coordinate e la data. [b]Save Image[/b] salva l'orientamento del nucleo con gli elementi selezionati per l'istante corrente.

[color=#E7B64A][b]FUNZIONE PREVISTA[/b][/color] Esportazione di un'animazione del movimento del nucleo per l'intervallo temporale impostato in Settings.

[img=384x192]res://asset/texture3.jpg[/img]

[font_size=19][color=#B7C7CF]Change Date / Hour[/color][/font_size]

Le frecce centrali avanzano o retrocedono di uno step, espresso in giorni oppure ore secondo l'intervallo configurato. Tenendole premute, le date scorrono rapidamente. Le frecce esterne raggiungono direttamente il primo o l'ultimo istante dell'intervallo.

Il modello viene aggiornato automaticamente e la data selezionata compare nell'anteprima del nucleo e nella finestra principale.""",

"""[font_size=26][color=#45B8CF]CCD Image e trasparenza[/color][/font_size]

[b]Load CCD Image[/b] carica l'immagine telescopica usata come riferimento. AETHER rileva automaticamente la dimensione in pixel e adatta l'immagine alla finestra principale. Per una visualizzazione ottimale è consigliata un'immagine quadrata con la cometa al centro.

[b]Formati disponibili nella versione corrente:[/b] FITS, FIT, FTS, PNG, JPG, JPEG e WebP. Per le immagini FITS bidimensionali non compresse, AETHER legge dati interi o floating point, applica BSCALE/BZERO e genera automaticamente una visualizzazione in scala di grigi con contrasto astronomico. I cubi FITS vengono visualizzati usando il primo piano. Se l’header contiene una scala angolare riconoscibile, la risoluzione in arcsec/pixel viene compilata automaticamente e può comunque essere modificata manualmente.
[color=#E7B64A][b]FORMATO PREVISTO DAL MANUALE[/b][/color] TIF sarà aggiunto alla procedura di caricamento.

Se la risoluzione non viene rilevata dall’header FITS, inseriscila manualmente in arcsec/pixel in base al sistema ottico. Usando la distanza dalla Terra [b]Delta[/b], importata da JPL Horizons, AETHER calcola la risoluzione in km/pixel e il FOV in chilometri e arcosecondi.

Lo switch CCD mostra o nasconde l'immagine, sostituendola con il fondo nero senza eliminarla.

[font_size=19][color=#B7C7CF]Trasparenza[/color][/font_size]

Il cursore [b]Model[/b] varia l'opacità del modello numerico da 0%, modello invisibile, a 100%, modello completamente visibile. Il cursore [b]Image[/b] regola separatamente l'opacità dell'immagine telescopica. [b]Bright[/b] e [b]Contrast[/b] permettono di recuperare i dettagli delle immagini FITS senza modificare i dati scientifici originali.""",

"""[font_size=26][color=#45B8CF]Simulation[/color][/font_size]

[b]SIM[/b] esegue progressivamente la simulazione. Il cursore sottostante indica l'avanzamento del modello.

[b]PAUSE[/b] sospende l'esecuzione corrente. [b]STOP[/b] interrompe la simulazione. [b]INST[/b] genera immediatamente la riproduzione completa del modello.

[b]Save Image[/b] apre la finestra in cui scegliere cartella, nome del file e contenuto dell'esportazione. Il risultato può essere salvato su fondo nero oppure con trasparenza, così da sovrapporlo a immagini telescopiche anche in altri programmi, per esempio PowerPoint.

Le opzioni di salvataggio consentono inoltre di includere l'immagine CCD visibile e l'indicatore direzionale N/S/V. Il pulsante [b]NSV[/b] sotto la finestra principale mostra o nasconde l'indicatore: le tre frecce hanno la stessa origine e rappresentano Nord, direzione del Sole e vettore velocità.

[color=#E7B64A][b]FUNZIONE PREVISTA[/b][/color] [b]Save Animation[/b] permetterà di esportare l'animazione in GIF o MPEG e di scegliere la velocità di riproduzione.""",

"""[font_size=26][color=#45B8CF]Sun e Nucleus and Spin Axis[/color][/font_size]

[font_size=19][color=#B7C7CF]Sun[/color][/font_size]

Non è richiesta l'immissione manuale. Dopo l'importazione da JPL Horizons compaiono automaticamente:

• distanza eliocentrica r;
• position angle del Sole, Sun PA;
• angolo di fase Sole bersaglio osservatore, STO;
• latitudine subsolare calcolata per la data corrente.

[font_size=19][color=#B7C7CF]Nucleus and Spin Axis[/color][/font_size]

Inserisci il raggio del nucleo in chilometri, il periodo di rotazione in ore e il numero di rotazioni da utilizzare nel modello.

L'orientamento dell'asse può essere definito in due modi:

1. Inserisci le coordinate equatoriali RA e Dec in gradi decimali; AETHER calcola position angle e inclinazione dell'asse rispetto al piano del cielo.
2. Inserisci manualmente Spin Axis PA e Spin Axis Inclination; usando la posizione della cometa nelle effemeridi della data corrente, AETHER calcola RA e Dec. Il PA è misurato dal Nord verso Est; l'inclinazione vale 0° sul piano del cielo, −90° verso l'osservatore e +90° nella direzione opposta.

In entrambi i casi vengono calcolate le coordinate eclittiche λ e β e le coordinate orbitali Φ e I.""",

"""[font_size=26][color=#45B8CF]Dust[/color][/font_size]

La sezione definisce diametro, densità e albedo delle particelle. Nella versione corrente è disponibile un valore per il diametro e uno per la densità. Beta e accelerazione dovuta alla pressione di radiazione vengono calcolate da diametro, densità e distanza dal Sole assumendo Qpr = 1. Come richiesto dal modello, l'albedo resta disponibile come proprietà ottica ma non entra nella formula di Beta.

[color=#E7B64A][b]MODELLO DI DISTRIBUZIONE PREVISTO DAL MANUALE[/b][/color]

• Diametro minimo da 0 a 10 μm, con step di 0,1 μm.
• Diametro massimo da 10 a 200 μm, con step di 5 μm.
• Inserimento manuale dei diametri con precisione fino a due decimali.
• Densità separata per ciascun diametro, da 0 a 3 g/dm³ con step di 0,1 g/dm³.
• Percentuale desiderata di particelle piccole e grandi per descrivere una distribuzione dimensionale ipotetica.

Con questi dati AETHER calcolerà separatamente i valori beta e l'accelerazione risultante, espressa in m/s², dovuta alla pressione di radiazione. I risultati mostrano N/A finché diametro, densità e distanza dal Sole non hanno valori positivi.""",

"""[font_size=26][color=#45B8CF]Dust Jets[/color][/font_size]

Questa sezione definisce le regioni attive sul nucleo. [b]Integration step (min)[/b] indica l'intervallo, in minuti, usato per generare le emissioni di polvere nel modello. Il valore minimo accettato è 0,5 minuti; diminuendolo si ottiene una risoluzione temporale maggiore e aumenta il numero di passi da calcolare.

Il manuale prevede fino a cinque regioni attive iniziali e consente di aggiungerne altre quando necessario. Per ogni regione specifica:

• velocità di emissione in m/s;
• posizione sul nucleo tramite latitudine e longitudine in gradi;
• numero totale di particelle emesse a ogni step, impostabile separatamente per ogni getto;
• diffusione percentuale intorno alla traiettoria centrale;
• colore usato per distinguere l'emissione nel modello.

Il comando [b]Toggle[/b] mostra o nasconde la singola regione attiva. [b]Remove[/b] la elimina.

[color=#B7C7CF]Esempio: crea due regioni attive con colori diversi, assegna velocità e diffusione differenti e usa Toggle per confrontare separatamente il loro contributo al modello.[/color]""",
]

const CONTENT_EN := [
"""[font_size=26][color=#45B8CF]AETHER HELP[/color][/font_size]

AETHER lets you configure a comet, retrieve ephemerides from JPL Horizons, build a dust emission model and compare it with a telescopic image.

[font_size=19][color=#B7C7CF]Top bar[/color][/font_size]

[img=24x24]res://asset/save_icon.png[/img]  [b]Down arrow[/b]
Saves a configuration file containing the parameters set for the comet and the loaded image data for the current date.

[img=24x24]res://asset/load_icon.png[/img]  [b]Up arrow[/b]
Loads a previously saved configuration file.

[font_size=19][color=#B7C7CF]Recommended workflow[/color][/font_size]

1. Enter the comet, observation interval and step in Settings.
2. Retrieve orbital elements and ephemerides with the search button.
3. Open Model and configure the nucleus, spin axis, dust and active regions.
4. Load the CCD image, run the model and compare the results.
5. Save the configuration, image or CSV data.

[color=#E7B64A][b]Example[/b][/color] Search for 67P, select a short interval with a 24 hour step and complete the model with physical parameters from literature or observations. This example explains the workflow and is not a scientific preset.""",

"""[font_size=26][color=#45B8CF]Settings tab[/color][/font_size]

Settings is the opening screen. Enter the comet name or designation and select the observation interval. Dates can be typed as dd/mm/yyyy or selected with [img=22x22]res://asset/Calendar32x32.png[/img].

[b]Step Size (h)[/b] sets the interval between ephemeris rows. The manual specifies values from 1 to 24 hours; 24 hours gives one daily step.

Press the search icon [img=22x22]res://asset/search_icon.png[/img] to connect to JPL Horizons and retrieve the orbital elements. They appear in [b]Orbital Elements[/b], while [b]Ephemeris results[/b] displays the ephemerides.

The [b]Table Settings[/b] checkboxes select the table data: astrometric coordinates, observer range, subsolar angle, heliocentric range, phase angle, orbital plane angle, true anomaly, [b]PsAMV[/b] and apparent motion direction. PsAMV is the position angle of the projected negative heliocentric velocity and indicates the expected dust-tail direction.

[b]EXPORT CSV[/b] saves the ephemerides for analysis in external software such as Excel. After retrieving the data, proceed to Model.""",

"""[font_size=26][color=#45B8CF]Main viewport[/color][/font_size]

The main viewport displays the generated model and the loaded telescopic image. The model can be overlaid with adjustable transparency or displayed on a black background.

The controls below the viewport can show:

• a coordinate grid in decimal degrees;
• the current date or time;
• a ruler in arcseconds or kilometres, one sixth of the image FOV long.

[img=24x24]res://asset/32x32_grid.png[/img] toggles the grid. [b]Overlays[/b] changes grid, date and scale between white and black, including in saved images.

[font_size=19][color=#B7C7CF]Mouse and keyboard controls[/color][/font_size]

• Hold the right mouse button and drag to orbit around the comet.
• Scroll the wheel up to zoom in.
• Scroll the wheel down to zoom out.
• Press [b]R[/b] to restore position, correct scale and geocentric view.

Side sections can be collapsed with −. The central viewport expands when every section in a column is collapsed.

The ⛶ button in the viewport corner opens the model-only full-screen view. Press the button again, [b]F11[/b] or [b]Esc[/b] to restore every panel.""",

"""[font_size=26][color=#45B8CF]Nucleus Model and Change Date / Hour[/color][/font_size]

This panel shows the nucleus and its illumination according to the observation geometry and Sun position.

The buttons below the preview show or hide:

[color=#F2E94E]■ Sun direction, yellow[/color]
[color=#45D65A]■ spin axis, green[/color]
[color=#32B8E6]■ apparent-velocity vector (JPL Sky mot PA), cyan[/color]

The green-axis button shows or hides both halves of the spin axis together. The velocity button works independently from the Sun direction and spin axis.

A coordinate grid and the date are also available. [b]Save Image[/b] saves the nucleus orientation with the selected elements for the current instant.

[color=#E7B64A][b]PLANNED FEATURE[/b][/color] Exporting an animation of the nucleus motion for the time interval selected in Settings.

[img=384x192]res://asset/texture3.jpg[/img]

[font_size=19][color=#B7C7CF]Change Date / Hour[/color][/font_size]

The central arrows move backward or forward by one step, expressed in days or hours according to the selected interval. Hold an arrow to scroll quickly. The outer arrows jump directly to the first or last instant in the interval.

The model updates automatically, and the selected date is displayed in both the nucleus preview and main viewport.""",

"""[font_size=26][color=#45B8CF]CCD Image and transparency[/color][/font_size]

[b]Load CCD Image[/b] loads the telescopic reference image. AETHER automatically detects its pixel dimensions and adapts it to the main viewport. A square image with the comet centred is recommended.

[b]Formats available in the current build:[/b] FITS, FIT, FTS, PNG, JPG, JPEG and WebP. For uncompressed two-dimensional FITS images, AETHER reads integer or floating-point data, applies BSCALE/BZERO and automatically creates an astronomical-contrast grayscale view. FITS cubes are displayed using their first plane. If the header contains a recognised angular scale, the arcsec/pixel resolution is filled automatically and can still be edited manually.
[color=#E7B64A][b]FORMAT PLANNED BY THE MANUAL[/b][/color] TIF will be added to the loading workflow.

If the resolution is not detected in the FITS header, enter it manually in arcsec/pixel for the optical system. Using the Earth range [b]Delta[/b] imported from JPL Horizons, AETHER calculates the resolution in km/pixel and the FOV in kilometres and arcseconds.

The CCD switch shows or hides the image, replacing it with a black background without removing it.

[font_size=19][color=#B7C7CF]Transparency[/color][/font_size]

The [b]Model[/b] slider changes numerical model opacity from 0%, invisible, to 100%, fully visible. The [b]Image[/b] slider separately controls telescopic image opacity. [b]Bright[/b] and [b]Contrast[/b] recover FITS image detail without changing the original scientific data.""",

"""[font_size=26][color=#45B8CF]Simulation[/color][/font_size]

[b]SIM[/b] runs the simulation progressively. The slider below indicates model progress.

[b]PAUSE[/b] suspends the current run. [b]STOP[/b] interrupts the simulation. [b]INST[/b] immediately generates the complete model playback.

[b]Save Image[/b] opens a window for choosing the folder, file name and export content. The result can be saved on a black background or with transparency, allowing it to be overlaid on telescopic images in other software such as PowerPoint.

Save options can also include the visible CCD image and N/S/V direction indicator. The [b]NSV[/b] button below the main viewport shows or hides the indicator; its three arrows share one origin and represent North, Sun direction and velocity vector.

[color=#E7B64A][b]PLANNED FEATURE[/b][/color] [b]Save Animation[/b] will export an animation as GIF or MPEG and allow the playback speed to be selected.""",

"""[font_size=26][color=#45B8CF]Sun and Nucleus and Spin Axis[/color][/font_size]

[font_size=19][color=#B7C7CF]Sun[/color][/font_size]

No manual input is required. After importing from JPL Horizons, AETHER automatically displays:

• heliocentric range r;
• Sun position angle, Sun PA;
• Sun target observer phase angle, STO;
• subsolar latitude calculated for the current date.

[font_size=19][color=#B7C7CF]Nucleus and Spin Axis[/color][/font_size]

Enter the nucleus radius in kilometres, rotation period in hours and number of rotations used by the model.

The axis orientation can be defined in two ways:

1. Enter equatorial coordinates RA and Dec in decimal degrees; AETHER calculates position angle and axis inclination relative to the sky plane.
2. Enter Spin Axis PA and Spin Axis Inclination manually; using the comet position in the current date's ephemeris, AETHER calculates RA and Dec. PA is measured from North towards East; inclination is 0° in the sky plane, −90° towards the observer and +90° away.

In both cases, the ecliptic coordinates λ and β and orbital coordinates Φ and I are calculated automatically.""",

"""[font_size=26][color=#45B8CF]Dust[/color][/font_size]

This section defines particle diameter, density and albedo. The current build provides one diameter and one density value. Radiation-pressure beta and acceleration are calculated from diameter, density and Sun distance with Qpr = 1. As required by the model, albedo remains available as an optical property but is excluded from the Beta formula.

[color=#E7B64A][b]DISTRIBUTION MODEL PLANNED BY THE MANUAL[/b][/color]

• Minimum diameter from 0 to 10 μm in 0.1 μm steps.
• Maximum diameter from 10 to 200 μm in 5 μm steps.
• Manual diameter entry with up to two decimal places.
• Separate density for each diameter, from 0 to 3 g/dm³ in 0.1 g/dm³ steps.
• Desired percentage of small and large particles for a hypothetical size distribution.

With these values, AETHER will separately calculate particle beta values and the resulting radiation pressure acceleration in m/s². The results display N/A until diameter, density and Sun distance are all positive.""",

"""[font_size=26][color=#45B8CF]Dust Jets[/color][/font_size]

This section defines active regions on the nucleus. [b]Integration step (min)[/b] is the interval in minutes used to generate dust emissions in the model. The minimum accepted value is 0.5 minutes; reducing it increases temporal resolution and the number of calculation steps.

The manual provides up to five initial active regions and allows additional regions to be added when needed. For each region, specify:

• emission speed in m/s;
• position on the nucleus as latitude and longitude in degrees;
• total particles emitted at each step, set independently for every jet;
• diffusion percentage around the central trajectory;
• a colour used to distinguish the emission in the model.

[b]Toggle[/b] shows or hides an individual active region. [b]Remove[/b] deletes it.

[color=#B7C7CF]Example: create two active regions with different colours, speeds and diffusion values, then use Toggle to compare their separate contributions to the model.[/color]""",
]

static func section_names(language: String) -> Array:
	return SECTION_NAMES_IT if language == "it" else SECTION_NAMES_EN

static func section(language: String, index: int) -> String:
	var content := CONTENT_IT if language == "it" else CONTENT_EN
	return content[clampi(index, 0, content.size() - 1)]
