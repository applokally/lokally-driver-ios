import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';

class LokallyBillingWidget extends StatelessWidget {
  const LokallyBillingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (walletController) {
        if (walletController.isLokallyBillingLoading &&
            walletController.lokallyBillingOverview == null) {
          return const Padding(
            padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final Map<String, dynamic>? overview =
            walletController.lokallyBillingOverview;

        if (overview == null) {
          return _EmptyBillingState(
            title: 'Pagar à Lokally',
            description:
                'Não foi possível carregar suas informações de pagamento.',
            actionLabel: 'Tentar novamente',
            onAction: walletController.getLokallyBillingOverview,
          );
        }

        final Map<String, dynamic> payToLokally =
            _asMap(overview['pay_to_lokally']);
        final Map<String, dynamic> weeklyCommission =
            _asMap(overview['weekly_commission']);
        final Map<String, dynamic> monthlyBilling =
            _asMap(overview['monthly_billing']);
        final Map<String, dynamic> paymentProfile =
            _asMap(overview['payment_profile']);

        final bool showBillingArea = overview['show_billing_area'] == true;
        final bool canGeneratePix = payToLokally['can_generate_pix'] == true;
        final bool hasPayableBilling =
            payToLokally['has_payable_billing'] == true;
        final String billingType =
            _stringValue(payToLokally['pix_billing_type']);
        final Map<String, dynamic> activeBilling =
            _asMap(payToLokally['active_billing']);
        final bool hasValidDocument =
            paymentProfile['has_valid_document'] == true;
        final List<String> missingFields =
            _asStringList(paymentProfile['missing_fields']);

        if (!showBillingArea) {
          return _EmptyBillingState(
            title: 'Pagar à Lokally',
            description:
                'Você não possui cobranças ativas com a Lokally neste momento.',
            actionLabel: 'Atualizar',
            onAction: walletController.getLokallyBillingOverview,
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BillingHeader(
                title: _stringValue(
                  payToLokally['title'],
                  fallback: 'Pagar à Lokally',
                ),
                subtitle: _stringValue(payToLokally['billing_mode_label']),
                cycleLabel: _stringValue(payToLokally['cycle_label']),
                isRefreshing: walletController.isLokallyBillingLoading,
                onRefresh: walletController.getLokallyBillingOverview,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (!hasValidDocument) ...[
                _DocumentAlert(missingFields: missingFields),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
              if (activeBilling.isNotEmpty)
                _ActiveBillingCard(
                  billing: activeBilling,
                  billingType: billingType,
                  canGeneratePix: canGeneratePix,
                  isLoading: walletController.isLokallyBillingPixLoading,
                  onGeneratePix: () async {
                    await walletController.generateLokallyBillingPix(
                      billingId: _stringValue(activeBilling['id']),
                      billingType: billingType,
                    );
                  },
                )
              else if (billingType == 'weekly_commission')
                _WeeklyPreviewCard(weeklyCommission: weeklyCommission)
              else if (billingType == 'monthly')
                _MonthlyCycleCard(monthlyBilling: monthlyBilling)
              else
                const _BillingStateCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Sem cobrança disponível',
                  description:
                      'Não há uma cobrança disponível para pagamento neste momento.',
                ),
              if (walletController.lokallyBillingPayment != null) ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _PixPaymentCard(
                  payment: walletController.lokallyBillingPayment!,
                  onClose: walletController.clearLokallyBillingPayment,
                ),
              ],
              if (!hasPayableBilling &&
                  billingType == 'monthly' &&
                  monthlyBilling.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _MonthlyCycleCard(monthlyBilling: monthlyBilling),
              ],
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _BillingHistory(
                billingType: billingType,
                weeklyCommission: weeklyCommission,
                monthlyBilling: monthlyBilling,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BillingHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cycleLabel;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _BillingHeader({
    required this.title,
    required this.subtitle,
    required this.cycleLabel,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.68),
                      ),
                ),
              ],
              if (cycleLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  cycleLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: isRefreshing ? null : () => onRefresh(),
          icon: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _DocumentAlert extends StatelessWidget {
  final List<String> missingFields;

  const _DocumentAlert({required this.missingFields});

  @override
  Widget build(BuildContext context) {
    final String fields =
        missingFields.isEmpty ? 'CPF ou CNPJ válido' : missingFields.join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'Para gerar seu Pix, informe $fields no seu perfil.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBillingCard extends StatelessWidget {
  final Map<String, dynamic> billing;
  final String billingType;
  final bool canGeneratePix;
  final bool isLoading;
  final Future<void> Function() onGeneratePix;

  const _ActiveBillingCard({
    required this.billing,
    required this.billingType,
    required this.canGeneratePix,
    required this.isLoading,
    required this.onGeneratePix,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = billing['is_overdue'] == true;
    final Color statusColor =
        isOverdue ? Colors.red : Theme.of(context).primaryColor;

    final String statusLabel = _stringValue(
      billing['status_label'],
      fallback: 'Aguardando pagamento',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOverdue
                    ? Icons.error_outline_rounded
                    : Icons.account_balance_wallet_outlined,
                color: statusColor,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  isOverdue ? 'Pagamento vencido' : 'Pagamento pendente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                statusLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            _currencyValue(billing['total_amount']),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _InfoRow(
            label: billingType == 'monthly' ? 'Período' : 'Ciclo',
            value: _billingPeriodLabel(billing),
          ),
          _InfoRow(
            label: 'Vencimento',
            value: _dateValue(billing['due_at']),
          ),
          if (billingType == 'weekly_commission')
            _InfoRow(
              label: 'Corridas no ciclo',
              value: _stringValue(billing['commission_count']),
            ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  !canGeneratePix || isLoading ? null : () => onGeneratePix(),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.qr_code_2_rounded),
              label: Text(isLoading ? 'Gerando Pix...' : 'Gerar Pix'),
            ),
          ),
          if (!canGeneratePix) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Cadastre um CPF ou CNPJ válido no perfil para liberar o Pix.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyPreviewCard extends StatelessWidget {
  final Map<String, dynamic> weeklyCommission;

  const _WeeklyPreviewCard({required this.weeklyCommission});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> preview = _asMap(weeklyCommission['preview']);
    final Map<String, dynamic> currentPeriod =
        _asMap(weeklyCommission['current_period']);
    final List<Map<String, dynamic>> items = _asMapList(preview['items']);

    return _BillingStateCard(
      icon: Icons.calendar_month_outlined,
      title: 'Prévia do ciclo atual',
      children: [
        _InfoRow(
          label: 'Comissão acumulada',
          value: _currencyValue(preview['total_amount']),
        ),
        _InfoRow(
          label: 'Corridas incluídas',
          value: _stringValue(preview['total_items']),
        ),
        _InfoRow(
          label: 'Fechamento',
          value: _dateOnlyValue(currentPeriod['closing_at']),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          'A fatura será disponibilizada após o fechamento do ciclo semanal.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Divider(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.receipt_long_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Ver corridas do ciclo (${items.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: Dimensions.paddingSizeSmall,
                    bottom: Dimensions.paddingSizeSmall,
                  ),
                  child: Text(
                    'Nenhuma corrida com taxa acumulada neste ciclo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...items.map(
                  (item) => _WeeklyCommissionItem(item: item),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyCommissionItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _WeeklyCommissionItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final String tripReference = _stringValue(item['trip_reference']);
    final String tripDateTime = _dateValue(item['commission_created_at']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tripReference.isNotEmpty) ...[
            Text(
              'Corrida $tripReference',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            tripDateTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Taxa Lokally',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                _currencyValue(item['commission_amount']),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyCycleCard extends StatelessWidget {
  final Map<String, dynamic> monthlyBilling;

  const _MonthlyCycleCard({required this.monthlyBilling});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> cycle = _asMap(monthlyBilling['cycle']);
    final bool awaitingVehicleApproval =
        cycle['awaiting_vehicle_approval'] == true;
    final bool awaitingCycleActivation =
        cycle['awaiting_cycle_activation'] == true;
    final bool hasStarted = cycle['has_started'] == true;

    String title = 'Mensalidade';
    String description =
        'Não há mensalidade pendente de pagamento neste momento.';

    if (awaitingVehicleApproval) {
      title = 'Aguardando aprovação do veículo';
      description =
          'Sua mensalidade será liberada quando seu veículo for aprovado e ativado.';
    } else if (awaitingCycleActivation) {
      title = 'Ativação da mensalidade';
      description =
          'Seu veículo já está aprovado. Aguarde a disponibilização do ciclo mensal.';
    } else if (hasStarted) {
      title = 'Ciclo mensal ativo';
      description =
          'A próxima cobrança será liberada cinco dias antes do vencimento.';
    }

    return _BillingStateCard(
      icon: Icons.event_repeat_outlined,
      title: title,
      children: [
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_stringValue(cycle['initial_payment_due_at']).isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _InfoRow(
            label: 'Primeiro vencimento',
            value: _dateValue(cycle['initial_payment_due_at']),
          ),
        ],
        if (_stringValue(cycle['anchor_at']).isNotEmpty)
          _InfoRow(
            label: 'Início do ciclo',
            value: _dateValue(cycle['anchor_at']),
          ),
      ],
    );
  }
}

class _PixPaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onClose;

  const _PixPaymentCard({
    required this.payment,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final String pixCopyPaste = _firstStringValue(
      payment,
      [
        'pix_copy_paste',
        'pix_code',
        'copy_paste',
        'qr_code',
      ],
    );

    final String paymentReference = _firstStringValue(
      payment,
      [
        'payment_reference',
        'reference',
        'external_reference',
      ],
    );

    return _BillingStateCard(
      icon: Icons.qr_code_rounded,
      title: 'Pix gerado',
      trailing: IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Fechar',
      ),
      children: [
        Text(
          pixCopyPaste.isEmpty
              ? 'O Pix foi gerado. Atualize a tela em alguns instantes para consultar os dados do pagamento.'
              : 'Copie o código Pix e conclua o pagamento no aplicativo do seu banco.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (paymentReference.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _InfoRow(
            label: 'Referência',
            value: paymentReference,
          ),
        ],
        if (pixCopyPaste.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              pixCopyPaste,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: pixCopyPaste),
                );

                showCustomSnackBar(
                  'Código Pix copiado.',
                  isError: false,
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar código Pix'),
            ),
          ),
        ],
      ],
    );
  }
}

class _BillingHistory extends StatelessWidget {
  final String billingType;
  final Map<String, dynamic> weeklyCommission;
  final Map<String, dynamic> monthlyBilling;

  const _BillingHistory({
    required this.billingType,
    required this.weeklyCommission,
    required this.monthlyBilling,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> periods =
        billingType == 'weekly_commission'
            ? _asMapList(weeklyCommission['periods'])
            : _asMapList(monthlyBilling['periods']);

    if (periods.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de cobranças',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...periods.map(
          (billing) {
            final bool isPaid =
                _stringValue(billing['display_status']) == 'paid';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: Dimensions.paddingSizeSmall,
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_outline_rounded
                        : Icons.receipt_long_outlined,
                    color:
                        isPaid ? Colors.green : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _billingPeriodLabel(billing),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stringValue(
                            billing['status_label'],
                            fallback: 'Cobrança',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    _currencyValue(billing['total_amount']),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BillingStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? trailing;
  final List<Widget> children;

  const _BillingStateCard({
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _EmptyBillingState extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _EmptyBillingState({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault,
        100,
      ),
      child: _BillingStateCard(
        icon: Icons.receipt_long_outlined,
        title: title,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          OutlinedButton.icon(
            onPressed: () => onAction(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.62),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value
      .map((item) => _stringValue(item))
      .where((item) => item.isNotEmpty)
      .toList();
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final String stringValue = value.toString().trim();

  return stringValue.isEmpty ? fallback : stringValue;
}

String _firstStringValue(
  Map<String, dynamic> values,
  List<String> keys,
) {
  for (final String key in keys) {
    final String value = _stringValue(values[key]);

    if (value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

String _currencyValue(dynamic value) {
  double amount = 0;

  if (value is num) {
    amount = value.toDouble();
  } else if (value != null) {
    final String normalized = value
        .toString()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    amount = double.tryParse(normalized) ?? 0;
  }

  final String amountText = amount.toStringAsFixed(2).replaceAll('.', ',');

  return 'R\$ $amountText';
}

String _dateValue(dynamic value) {
  final String rawValue = _stringValue(value);

  if (rawValue.isEmpty) {
    return '-';
  }

  final DateTime? parsed = DateTime.tryParse(rawValue);

  if (parsed == null) {
    return rawValue;
  }

  final DateTime date = parsed.toLocal();
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String year = date.year.toString();
  final bool hasTime = rawValue.contains('T') || rawValue.contains(':');

  if (!hasTime) {
    return '$day/$month/$year';
  }

  final String hour = date.hour.toString().padLeft(2, '0');
  final String minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/$year às $hour:$minute';
}

String _dateOnlyValue(dynamic value) {
  final String rawValue = _stringValue(value);

  if (rawValue.isEmpty) {
    return '-';
  }

  final DateTime? parsed = DateTime.tryParse(rawValue);

  if (parsed == null) {
    return rawValue;
  }

  final DateTime date = parsed.toLocal();
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String year = date.year.toString();

  return '$day/$month/$year';
}

String _billingPeriodLabel(Map<String, dynamic> billing) {
  final String start = _dateValue(billing['period_start']);
  final String end = _dateValue(billing['period_end']);

  if (start == '-' && end == '-') {
    return 'Cobrança Lokally';
  }

  if (start == end || end == '-') {
    return start;
  }

  if (start == '-') {
    return end;
  }

  return '$start a $end';
}
