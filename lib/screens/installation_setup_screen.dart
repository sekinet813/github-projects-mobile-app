import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../config/app_config.dart';

/// Installation ID設定画面
///
/// バックエンドからインストール一覧を取得し、Installation IDを選択・設定できます
class InstallationSetupScreen extends ConsumerStatefulWidget {
  const InstallationSetupScreen({super.key});

  @override
  ConsumerState<InstallationSetupScreen> createState() =>
      _InstallationSetupScreenState();
}

class _InstallationSetupScreenState
    extends ConsumerState<InstallationSetupScreen> {
  bool _isLoading = false;
  bool _isLoadingInstallations = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _installations = [];
  String? _selectedInstallationId;

  @override
  void initState() {
    super.initState();
    _loadInstallations();
  }

  Future<void> _loadInstallations() async {
    final authRepository = ref.read(githubAuthRepositoryProvider);

    setState(() {
      _isLoadingInstallations = true;
      _errorMessage = null;
    });

    try {
      final installations = await authRepository.getInstallations();

      setState(() {
        _installations = installations;
        _isLoadingInstallations = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'インストール一覧の取得に失敗しました: $e';
        _isLoadingInstallations = false;
      });
    }
  }

  Future<void> _saveInstallationId() async {
    if (_selectedInstallationId == null || _selectedInstallationId!.isEmpty) {
      setState(() {
        _errorMessage = 'Installation IDを選択してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Installation IDを保存
      await AppConfig.saveInstallationId(_selectedInstallationId!);

      if (!mounted) {
        return;
      }

      // 前の画面に戻る
      Navigator.of(context).pop(_selectedInstallationId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '保存に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation ID設定'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'GitHub App Installation IDを設定',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'バックエンドからインストール一覧を取得し、使用するInstallation IDを選択してください。',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isLoadingInstallations) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ] else if (_installations.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'インストールが見つかりませんでした。\n'
                      'GitHub Appをインストールしてください。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadInstallations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再読み込み'),
                  ),
                ] else ...[
                  ..._installations.map((installation) {
                    final id = installation['id']?.toString() ?? '';
                    final account =
                        installation['account'] as Map<String, dynamic>?;
                    final login = account?['login'] as String? ?? 'Unknown';
                    final type = account?['type'] as String? ?? 'Unknown';
                    final targetType =
                        installation['target_type'] as String? ?? 'Unknown';

                    return Card(
                      child: RadioListTile<String>(
                        title: Text(login),
                        subtitle: Text('$type / $targetType'),
                        value: id,
                        groupValue: _selectedInstallationId,
                        onChanged: (value) {
                          setState(() {
                            _selectedInstallationId = value;
                            _errorMessage = null;
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveInstallationId,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
