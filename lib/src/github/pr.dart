class PR {
  PR(this.id);
  final int id;

  bool operator ==(other) {
    return (other is PR) && other.id == id;
  }
}
