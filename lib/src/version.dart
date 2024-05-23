/// Phoenix socket protocol version
enum Version {
  v1('1.0.0'),
  v2('2.0.0');

  final String xyz;
  const Version(this.xyz);
}
