String translateAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid credentials')) {
    return 'E-mail ou senha incorretos';
  }
  if (lower.contains('email not confirmed')) {
    return 'E-mail não confirmado. Verifique sua caixa de entrada';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already been registered')) {
    return 'Este e-mail já está cadastrado';
  }
  if (lower.contains('password') && lower.contains('at least')) {
    return 'A senha deve ter pelo menos 6 caracteres';
  }
  if (lower.contains('same password') ||
      lower.contains('different from the old')) {
    return 'A nova senha deve ser diferente da atual';
  }
  if (lower.contains('too many requests') ||
      lower.contains('rate limit')) {
    return 'Muitas tentativas. Aguarde um momento';
  }
  if (lower.contains('user not found')) {
    return 'Usuário não encontrado';
  }
  if (lower.contains('network') || lower.contains('socket') ||
      lower.contains('failed host lookup')) {
    return 'Erro de conexão. Verifique sua internet';
  }
  if (lower.contains('email') && lower.contains('invalid')) {
    return 'E-mail inválido';
  }
  if (lower.contains('signup is disabled')) {
    return 'Cadastro desabilitado temporariamente';
  }
  return message;
}
