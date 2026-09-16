# Modificare l’interfaccia in Godot

Apri `hud.tscn` nella vista 2D e seleziona il nodo `EditorPreview`.
Nell’Inspector, **Editor Page** permette di mostrare Settings, Model, Help o Credits.
È un’anteprima per lavorare nell’editor; l’applicazione si apre sempre su Settings.

I controlli, le posizioni e le dimensioni delle pagine sono salvati nella scena.
Puoi modificarli dall’Inspector e con gli strumenti della vista 2D.
**Automatic Layout**, sul nodo principale `Hud`, è disattivato: il codice rispetta le geometrie salvate.
Attivandolo, riabiliti le regole di disposizione automatica, che possono sostituire
le posizioni e le dimensioni impostate a mano.
Per adattare un layout manuale a finestre diverse, usa ancoraggi e contenitori di Godot.

La riduzione delle sezioni di Model e la modalità a schermo intero continuano
a modificare temporaneamente la disposizione durante l’uso dell’applicazione.

La pagina Credits si trova in `CreditsPageLayer/Background/CreditsPanel`.
Il testo italiano dei contributori è nel nodo `CreditsContent` e usa BBCode.
I pulsanti delle sezioni sono in `Navigation`; `ButtonIta` e `ButtonEng` cambiano
la lingua dei Credits. Le traduzioni descrittive sono in `scripts/credits_page.gd`.
Titoli e navigazione Help sono in `Body/HelpPanel/HelpContentPanel/CometPanel`.
Il contenuto delle sezioni Help e le traduzioni vengono caricati da
`scripts/help_content.gd`; effemeridi, versione e licenze sono dati aggiornati all’avvio.

Il tema condiviso è `aether_theme.tres`, modificabile nell’editor delle risorse Theme.
Le proprietà locali dei singoli controlli possono prevalere sul tema condiviso.
Mantieni i nomi e i percorsi dei nodi: gli script li usano per le interazioni.
Le righe dei getti, le effemeridi e le finestre legate ai dati continuano a essere
generate durante l’esecuzione.
