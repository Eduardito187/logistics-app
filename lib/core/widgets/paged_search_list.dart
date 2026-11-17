import 'dart:async';

import 'package:flutter/material.dart';

import '../icons/icons.dart';
import '../layout/nav_clearance.dart';
import '../layout/responsive_body.dart';
import '../network/api_exception.dart';
import 'async_value_view.dart';
import 'empty_state.dart';
import 'field_icon.dart';
import 'paged.dart';

/// Trae una página de resultados para [query] (ya recortado).
typedef PagedFetch<T> = Future<Paged<T>> Function(String query, int page);

/// Lista con **buscador** y **carga por páginas**.
///
/// Base común de Camiones, Envíos y Personal: un campo de búsqueda que consulta
/// al servidor (con una pausa corta al tipear, para no pedir en cada tecla),
/// filtros opcionales arriba, tirar para refrescar y la página siguiente al
/// acercarse al final. Solo construye las filas visibles.
class PagedSearchList<T> extends StatefulWidget {
  const PagedSearchList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.emptyTitle,
    this.searchLabel = 'Buscar',
    this.showSearch = true,
    this.searchHint,
    this.emptyIcon = AppIcon.search,
    this.filters,
    this.filterKey,
    this.debounce = const Duration(milliseconds: 350),
  });

  final PagedFetch<T> fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String searchLabel;
  final String? searchHint;

  /// `false` para listas sin buscador (pestañas de una ficha): solo páginas y
  /// tirar para refrescar.
  final bool showSearch;
  final String emptyTitle;
  final AppIcon emptyIcon;

  /// Filtros que van debajo del buscador (chips, otro campo).
  final Widget? filters;

  /// Cambia cuando cambian los filtros: la lista vuelve a la página 1.
  final Object? filterKey;

  /// Pausa tras la última tecla antes de buscar.
  final Duration debounce;

  @override
  State<PagedSearchList<T>> createState() => PagedSearchListState<T>();
}

class PagedSearchListState<T> extends State<PagedSearchList<T>> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  /// Distancia al final (px) a la que se pide la página siguiente.
  static const double _loadMoreThreshold = 500;

  Timer? _debounce;
  List<T> _items = <T>[];
  String _query = '';
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  /// Sube con cada búsqueda nueva: una respuesta vieja ya no se pinta.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(reload());
  }

  @override
  void didUpdateWidget(PagedSearchList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterKey != widget.filterKey) unawaited(reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Vuelve a la página 1 con la búsqueda y los filtros actuales.
  Future<void> reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.fetch(_query, 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = page.items;
        _hasMore = page.hasMore;
        _page = 1;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = <T>[];
        _hasMore = false;
        _error = error;
        _loading = false;
      });
    }
  }

  /// Vuelve a pedir las páginas YA cargadas sin spinner y sin mover la lista
  /// (para avisos de tiempo real: el dato cambia en su lugar). Si algo falla
  /// se conserva lo que se ve.
  Future<void> refreshSilently() async {
    if (_loading || _loadingMore) return;
    final generation = _generation;
    final pages = _page;
    try {
      final items = <T>[];
      var hasMore = false;
      var loaded = 0;
      for (var page = 1; page <= pages; page++) {
        final result = await widget.fetch(_query, page);
        if (!mounted || generation != _generation) return;
        items.addAll(result.items);
        hasMore = result.hasMore;
        loaded = page;
        if (!hasMore) break;
      }
      setState(() {
        _items = items;
        _hasMore = hasMore;
        _page = loaded;
      });
    } on Object {
      // Se queda con lo visible.
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.fetch(_query, _page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...page.items];
        _hasMore = page.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } on Object {
      // Falló la página: se conserva lo visible; se reintenta al scrollear.
      if (!mounted || generation != _generation) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(_loadMore());
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _submit(text));
    // Para mostrar/ocultar el botón de borrar al instante.
    setState(() {});
  }

  void _submit(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query == _query) return;
    _query = query;
    unawaited(reload());
  }

  void _clear() {
    _search.clear();
    _submit('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    return ResponsiveBody(
      child: Column(
        children: [
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                onChanged: _onChanged,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  prefixIconConstraints: FieldIcon.prefixConstraints,
                  prefixIcon: FieldIcon(
                    icon: AppIcon.search,
                    focusNode: _focus,
                  ),
                  labelText: widget.searchLabel,
                  hintText: widget.searchHint,
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          icon: const AnimatedAppIcon(AppIcon.close, size: 20),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
          if (filters != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: filters,
            ),
          Expanded(
            child: RefreshIndicator(onRefresh: reload, child: _body(context)),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _items.isEmpty) return const LoadingView();
    final error = _error;
    if (error != null) {
      return _scrollable(
        EmptyState(
          icon: AppIcon.cloudOff,
          title: 'No se pudo cargar',
          message: error is ApiException ? error.message : 'Ocurrió un error.',
          action: FilledButton.icon(
            onPressed: reload,
            icon: const AnimatedAppIcon(AppIcon.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return _scrollable(
        EmptyState(
          icon: widget.emptyIcon,
          title: widget.emptyTitle,
          message: _query.isEmpty ? null : 'Probá con otra búsqueda.',
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 12, 16, navScrollBottomPadding(context)),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.itemBuilder(context, _items[index]),
          );
        }
        return _Footer(
          loading: _loadingMore,
          hasMore: _hasMore,
          total: _items.length,
        );
      },
    );
  }

  /// Estados vacío/error scrolleables, para que "tirar para refrescar" ande.
  Widget _scrollable(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    ),
  );
}

/// Pie de la lista: cargando la página siguiente, o el total al terminar.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.hasMore,
    required this.total,
  });

  final bool loading;
  final bool hasMore;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
        ),
      );
    }
    if (hasMore) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          total == 1 ? '1 resultado' : '$total resultados',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
