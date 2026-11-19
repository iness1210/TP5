import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const AppTp5());

const _bleuNuit = Color(0xFF102A56);
const _bleu = Color(0xFF1769E0);
const _bleuClair = Color(0xFFDCEBFF);
const _bleuTresClair = Color(0xFFEEF5FF);
const _fond = Color(0xFFF5F8FF);
const _texte = Color(0xFF172B4D);
const _texteSecondaire = Color(0xFF64748B);
const _vert = Color(0xFF22A06B);
const _rougeAlerte = Color(0xFFDC3545);
const _titreWidget = 'Ruche · température';

class AppTp5 extends StatefulWidget {
  const AppTp5({super.key});

  @override
  State<AppTp5> createState() => _AppTp5State();
}

class _AppTp5State extends State<AppTp5> {
  bool _sombre = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _bleu,
            brightness: _sombre ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: _bleu,
            secondary: _sombre ? _bleuClair : _bleuNuit,
            surface: _sombre ? const Color(0xFF182338) : Colors.white,
            error: _rougeAlerte,
          ),
      scaffoldBackgroundColor: _sombre ? const Color(0xFF0D1524) : _fond,
      textTheme: (_sombre ? ThemeData.dark() : ThemeData.light()).textTheme
          .apply(
            bodyColor: _sombre ? const Color(0xFFE5ECF8) : _texte,
            displayColor: _sombre ? const Color(0xFFE5ECF8) : _texte,
          ),
      cardTheme: CardThemeData(
        color: _sombre ? const Color(0xFF182338) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _bleu,
        thumbColor: _bleu,
        inactiveTrackColor: _bleuClair,
        overlayColor: Color(0x1F1769E0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _sombre ? const Color(0xFF111B2B) : Colors.white,
        indicatorColor: _sombre ? const Color(0xFF263F62) : _bleuClair,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? (_sombre ? _bleuClair : _bleuNuit)
                : (_sombre ? const Color(0xFFADB9CC) : _texteSecondaire),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ruche connectée',
      theme: theme,
      home: PageWidget(
        sombre: _sombre,
        onModeSombreChange: (value) => setState(() => _sombre = value),
      ),
    );
  }
}

/// Tous les appels vers le code Kotlin du widget
class CanalWidget {
  static const _canal = MethodChannel('widget/maj');

  static Future<int> mettreAJour({
    required double valeur,
    String? titre,
    String? unite,
    double? seuil,
  }) async {
    final n = await _canal.invokeMethod<int>('mettreAJour', {
      'valeur': valeur,
      'titre': titre,
      'unite': unite,
      'seuil': seuil,
    });
    return n ?? 0;
  }

  static Future<int> nombreWidgets() async =>
      await _canal.invokeMethod<int>('nombreWidgets') ?? 0;

  static Future<bool> epingler() async =>
      await _canal.invokeMethod<bool>('epingler') ?? false;
}

class PageWidget extends StatefulWidget {
  const PageWidget({
    super.key,
    required this.sombre,
    required this.onModeSombreChange,
  });
  final bool sombre;
  final ValueChanged<bool> onModeSombreChange;

  @override
  State<PageWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> with WidgetsBindingObserver {
  double _valeur = 34;
  double _seuil = 38;
  int _nbWidgets = 0;
  bool _envoi = false;
  int _onglet = 0;
  DateTime? _dernierEnvoi;

  bool get _alerte => _valeur >= _seuil;
  bool get _modeSombre => widget.sombre;
  Color get _surface => _modeSombre ? const Color(0xFF182338) : Colors.white;
  Color get _titreColor => _modeSombre ? const Color(0xFFE5ECF8) : _bleuNuit;
  Color get _secondaireColor =>
      _modeSombre ? const Color(0xFFADB9CC) : _texteSecondaire;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _compter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _compter();
  }

  Future<void> _compter() async {
    try {
      final n = await CanalWidget.nombreWidgets();
      if (mounted) setState(() => _nbWidgets = n);
    } catch (_) {
      // Le canal n'est pas disponible dans les tests ou hors Android.
    }
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texte),
          behavior: SnackBarBehavior.floating,
          backgroundColor: erreur ? _rougeAlerte : _bleuNuit,
        ),
      );
  }

  Future<void> _envoyer() async {
    setState(() => _envoi = true);
    try {
      final n = await CanalWidget.mettreAJour(
        titre: _titreWidget,
        valeur: _valeur,
        unite: '°C',
        seuil: _seuil,
      );
      if (!mounted) return;
      setState(() {
        _nbWidgets = n;
        if (n > 0) _dernierEnvoi = DateTime.now();
      });
      _message(
        n == 0 ? "Aucun widget sur l'écran d'accueil" : 'Envoyé à $n widget(s)',
        erreur: n == 0,
      );
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}', erreur: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _epingler() async {
    final ok = await CanalWidget.epingler();
    if (!ok && mounted) {
      _message('Ajout automatique non pris en charge : ajoutez-le à la main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_onglet) {
            1 => _pageHistorique(),
            2 => _pageParametres(),
            _ => _pageAccueil(),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (index) => setState(() => _onglet = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  Widget _pageAccueil() => ListView(
    key: const ValueKey('accueil'),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      _enteteAccueil(),
      const SizedBox(height: 24),
      _carteTemperature(),
      const SizedBox(height: 14),
      _cartesEtat(),
      const SizedBox(height: 26),
      _titreSection('Détails du capteur'),
      const SizedBox(height: 12),
      _carteDetailsCapteur(),
      const SizedBox(height: 24),
      _titreSection('Alertes'),
      const SizedBox(height: 12),
      _carteAlerte(),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => setState(() => _onglet = 1),
        icon: const Icon(Icons.history_rounded),
        label: const Text('Voir l’historique'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _titreColor,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: _bleuClair),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _envoi ? null : _envoyer,
        icon: _envoi
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.sync_rounded),
        label: const Text('Envoyer au widget Android'),
        style: FilledButton.styleFrom(
          backgroundColor: _bleuNuit,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _enteteAccueil() => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_bleuNuit, _bleu],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.hive_rounded, color: Colors.white, size: 29),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruche connectée',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titreColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Smart Hive Monitor',
              style: TextStyle(
                color: _secondaireColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Actualiser le nombre de widgets',
        onPressed: _compter,
        style: IconButton.styleFrom(
          backgroundColor: _surface,
          foregroundColor: _titreColor,
          fixedSize: const Size(44, 44),
        ),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );

  Widget _carteTemperature() {
    final progression = ((_valeur - 20) / 30).clamp(0.0, 1.0);
    final statut = _alerte ? 'Critique' : 'Normale';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_bleuNuit, Color(0xFF164B91)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _bleuNuit.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.thermostat_rounded,
                color: Color(0xFFB8D7FF),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TEMPÉRATURE',
                  style: TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              _petitBadge(
                texte: 'SIMULATION',
                couleurFond: Colors.white.withValues(alpha: .12),
                couleurTexte: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${_valeur.toStringAsFixed(1)} °C',
              key: ValueKey(_valeur),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1.08,
              ),
            ),
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8FC2FF)),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                _alerte ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: _alerte
                    ? const Color(0xFFFFCFD3)
                    : const Color(0xFFA8E7C8),
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                statut,
                style: TextStyle(
                  color: _alerte
                      ? const Color(0xFFFFCFD3)
                      : const Color(0xFFA8E7C8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Plage simulée · 20–50 °C',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Color(0xFFDCEBFF), fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartesEtat() => Row(
    children: [
      Expanded(
        child: _carteEtat(
          icone: _alerte ? Icons.shield_outlined : Icons.shield_rounded,
          titre: 'Capteur',
          valeur: _alerte ? 'À surveiller' : 'Dans le seuil',
          couleur: _alerte ? _rougeAlerte : _vert,
          onTap: () => setState(() => _onglet = 2),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _carteEtat(
          icone: Icons.widgets_rounded,
          titre: 'Widget Android',
          valeur: '$_nbWidgets actif${_nbWidgets == 1 ? '' : 's'}',
          couleur: _bleu,
          onTap: () => setState(() => _onglet = 2),
        ),
      ),
    ],
  );

  Widget _carteEtat({
    required IconData icone,
    required String titre,
    required String valeur,
    required Color couleur,
    required VoidCallback onTap,
  }) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: couleur, size: 22),
            const SizedBox(height: 12),
            Text(
              titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _secondaireColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              valeur,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: couleur == _bleu ? _bleuNuit : couleur,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _carteDetailsCapteur() => _carteSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconeRonde(Icons.thermostat_rounded, _bleuClair, _bleu),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Température',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Valeur de démonstration',
                    style: TextStyle(color: _secondaireColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '${_valeur.toStringAsFixed(1)} °C',
                key: ValueKey(_valeur),
                style: TextStyle(
                  color: _titreColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ((_valeur - 20) / 30).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: _bleuTresClair,
            valueColor: AlwaysStoppedAnimation(_alerte ? _rougeAlerte : _bleu),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '20 °C',
              style: TextStyle(color: _secondaireColor, fontSize: 11),
            ),
            Expanded(
              child: Text(
                'Plage du simulateur',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondaireColor, fontSize: 11),
              ),
            ),
            Text(
              '50 °C',
              style: TextStyle(color: _secondaireColor, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _carteAlerte() {
    final couleur = _alerte ? _rougeAlerte : _vert;
    return _carteSurface(
      couleur: _alerte
          ? (_modeSombre ? const Color(0xFF3A2029) : const Color(0xFFFFF3F4))
          : _surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconeRonde(
            _alerte ? Icons.warning_amber_rounded : Icons.check_rounded,
            _alerte ? const Color(0xFFFFE0E3) : const Color(0xFFE2F5EC),
            couleur,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alerte ? 'Température au-dessus du seuil' : 'Aucune alerte',
                  style: TextStyle(color: couleur, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _alerte
                      ? '${_valeur.toStringAsFixed(1)} °C mesurés · seuil à ${_seuil.round()} °C'
                      : 'La valeur simulée reste sous le seuil de ${_seuil.round()} °C.',
                  style: TextStyle(
                    color: _secondaireColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageParametres() => ListView(
    key: const ValueKey('parametres'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      _entetePage(
        titre: 'Paramètres',
        sousTitre: 'Capteur de démonstration et widget Android',
        icone: Icons.tune_rounded,
      ),
      const SizedBox(height: 16),
      _carteSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            _modeSombre ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: _bleu,
          ),
          title: const Text('Mode sombre'),
          subtitle: Text(
            _modeSombre ? 'Thème sombre activé' : 'Thème clair activé',
            style: TextStyle(color: _secondaireColor),
          ),
          value: _modeSombre,
          onChanged: widget.onModeSombreChange,
        ),
      ),
      const SizedBox(height: 25),
      _titreSection('Simulation du capteur'),
      const SizedBox(height: 12),
      _carteReglage(
        icone: Icons.thermostat_rounded,
        libelle: 'Mesure simulée',
        valeurTexte: '${_valeur.toStringAsFixed(1)} °C',
        couleur: _alerte ? _rougeAlerte : _bleu,
        slider: Slider(
          value: _valeur,
          min: 20,
          max: 50,
          divisions: 60,
          activeColor: _alerte ? _rougeAlerte : _bleu,
          label: '${_valeur.toStringAsFixed(1)} °C',
          onChanged: (v) => setState(() => _valeur = v),
        ),
      ),
      const SizedBox(height: 12),
      _carteReglage(
        icone: Icons.warning_amber_rounded,
        libelle: "Seuil d'alerte",
        valeurTexte: '${_seuil.round()} °C',
        couleur: _bleu,
        slider: Slider(
          value: _seuil,
          min: 20,
          max: 50,
          divisions: 30,
          label: '${_seuil.round()} °C',
          onChanged: (v) => setState(() => _seuil = v),
        ),
      ),
      const SizedBox(height: 25),
      _titreSection('Widget écran d’accueil'),
      const SizedBox(height: 12),
      _carteWidgets(),
      const SizedBox(height: 12),
      _ApercuWidget(
        titre: _titreWidget,
        valeur: _valeur,
        alerte: _alerte,
        heure: _dernierEnvoi,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _envoi ? null : _envoyer,
        style: FilledButton.styleFrom(
          backgroundColor: _alerte ? _rougeAlerte : _bleuNuit,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: _envoi
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: const Text('Envoyer au widget'),
      ),
    ],
  );

  Widget _pageHistorique() => ListView(
    key: const ValueKey('historique'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      _entetePage(
        titre: 'Historique',
        sousTitre: 'Évolution des mesures',
        icone: Icons.history_rounded,
      ),
      const SizedBox(height: 22),
      _etatVide(
        icone: Icons.timeline_rounded,
        titre: 'Aucun historique disponible',
        description:
            'Cette version transmet la valeur actuelle au widget Android, '
            'mais ne conserve pas de relevés précédents.',
      ),
    ],
  );

  Widget _entetePage({
    required String titre,
    required String sousTitre,
    required IconData icone,
  }) => Row(
    children: [
      _iconeRonde(icone, _bleuClair, _bleuNuit, taille: 50),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: TextStyle(
                color: _titreColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sousTitre,
              style: TextStyle(color: _secondaireColor, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _etatVide({
    required IconData icone,
    required String titre,
    required String description,
  }) => _carteSurface(
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: _bleuTresClair,
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: _bleu, size: 30),
        ),
        const SizedBox(height: 18),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _titreColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondaireColor, fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );

  Widget _carteWidgets() {
    final aucun = _nbWidgets == 0;
    return _carteSurface(
      child: Row(
        children: [
          _iconeRonde(
            aucun ? Icons.widgets_outlined : Icons.widgets_rounded,
            aucun ? _bleuTresClair : const Color(0xFFE2F5EC),
            aucun ? _bleu : _vert,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aucun ? 'Aucun widget posé' : '$_nbWidgets widget(s) posé(s)',
                  style: TextStyle(
                    color: _titreColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Sur l'écran d'accueil",
                  style: TextStyle(color: _secondaireColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _epingler,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter'),
            style: FilledButton.styleFrom(
              foregroundColor: _titreColor,
              backgroundColor: _modeSombre
                  ? const Color(0xFF263F62)
                  : _bleuTresClair,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteReglage({
    required IconData icone,
    required String libelle,
    required String valeurTexte,
    required Color couleur,
    required Widget slider,
  }) => _carteSurface(
    padding: const EdgeInsets.fromLTRB(16, 15, 12, 5),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icone, color: couleur),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                libelle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                valeurTexte,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: couleur,
                ),
              ),
            ),
          ],
        ),
        slider,
      ],
    ),
  );

  Widget _titreSection(String texte) => Text(
    texte,
    style: TextStyle(
      color: _titreColor,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      letterSpacing: -.2,
    ),
  );

  Widget _carteSurface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
    Color? couleur,
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: couleur ?? _surface,
      borderRadius: BorderRadius.circular(21),
      boxShadow: [
        BoxShadow(
          color: _bleuNuit.withValues(alpha: .045),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  Widget _iconeRonde(
    IconData icone,
    Color fond,
    Color couleur, {
    double taille = 44,
  }) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
    child: Icon(icone, color: couleur, size: taille * .52),
  );

  Widget _petitBadge({
    required String texte,
    required Color couleurFond,
    required Color couleurTexte,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: couleurFond,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      texte,
      style: TextStyle(
        color: couleurTexte,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    ),
  );
}

/// Reproduit en Flutter l'apparence du widget Glance, pour prévisualiser avant l'envoi
class _ApercuWidget extends StatelessWidget {
  const _ApercuWidget({
    required this.titre,
    required this.valeur,
    required this.alerte,
    required this.heure,
  });

  final String titre;
  final double valeur;
  final bool alerte;
  final DateTime? heure;

  @override
  Widget build(BuildContext context) {
    final fond = alerte ? _rougeAlerte : _bleuNuit;
    final h = heure;
    final bas = alerte
        ? 'ALERTE'
        : h == null
        ? 'Pas encore envoyé'
        : 'Envoyé à ${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            fond,
            alerte ? const Color(0xFFB3261E) : const Color(0xFF164B91),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: fond.withValues(alpha: .13),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.hive_rounded, color: Color(0xFFB8D7FF), size: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${valeur.toStringAsFixed(1)} °C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bas,
                  style: const TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            alerte ? Icons.warning_rounded : Icons.thermostat_rounded,
            color: Colors.white.withValues(alpha: .9),
          ),
        ],
      ),
    );
  }
}
