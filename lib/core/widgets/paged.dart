/// Una página de una lista del administrador y si quedan más por traer.
class Paged<T> {
  const Paged({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}
