import 'package:flutter/material.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const _categories = [
    _Category(
      title: 'Banking & Deposits',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF66FCF1),
      articles: [
        _Article(
          title: 'How Fixed Deposits Work',
          tags: ['FD', 'Savings', 'Interest'],
          body: '''A Fixed Deposit (FD) lets you lock a lump sum with a bank for a set period — from 3 months to 5 years — in exchange for a guaranteed interest rate higher than a savings account.

Key points:
• Interest is paid monthly, quarterly, or at maturity depending on the product
• A 5% Withholding Tax (WHT) is deducted from interest earned — so a 10% gross rate becomes 9.5% after tax
• You cannot withdraw early without a penalty (usually forfeiting 1–2% interest)
• SLIC guarantees deposits up to LKR 600,000 per depositor per bank

When comparing FDs, always use the after-tax effective annual yield — SalliMate calculates this for you in the FD Comparison tool.''',
        ),
        _Article(
          title: 'Understanding Savings Account Interest',
          tags: ['Savings', 'Interest', 'WHT'],
          body: '''Most Sri Lankan savings accounts pay between 2% and 5% per annum. Here's what you need to know:

• Interest is usually calculated daily on the closing balance and credited monthly or quarterly
• The 5% WHT applies to all interest — it is deducted at source by the bank
• Minimum average balance requirements vary by bank — falling below can mean no interest or a fee
• Some banks offer tiered rates (higher balance = higher rate)

Tip: If you park more than LKR 500,000 idle in a savings account, compare it against a short-tenure FD — you could earn significantly more.''',
        ),
        _Article(
          title: 'SLIC Deposit Insurance — What It Covers',
          tags: ['Insurance', 'Deposits', 'Risk'],
          body: '''The Sri Lanka Insurance Corporation (SLIC) provides deposit insurance coverage through the Deposit Insurance Scheme managed by the CBSL.

• Coverage: Up to LKR 600,000 per depositor per licensed bank or finance company
• Covers: Savings, current accounts, FDs, and call deposits
• Does not cover: Foreign currency deposits, deposits with unlicensed institutions

If you hold more than LKR 600,000 in a single bank, consider splitting across multiple licensed institutions to maximise your insured coverage.''',
        ),
      ],
    ),
    _Category(
      title: 'Tax & Compliance',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFFD54F),
      articles: [
        _Article(
          title: 'How PAYE Income Tax Works',
          tags: ['PAYE', 'Income Tax', 'IRD'],
          body: '''PAYE (Pay As You Earn) is the system by which your employer deducts income tax from your salary each month and remits it to the Inland Revenue Department (IRD).

Tax-free allowance: LKR 1,800,000 per year (LKR 150,000/month)

If your annual income exceeds this, the excess is taxed in progressive slabs:
• First LKR 1,000,000 above threshold: 6%
• Next LKR 500,000: 18%
• Next LKR 500,000: 24%
• Next LKR 500,000: 30%
• Balance above LKR 2,500,000: 36%

Your employer issues a PAYE certificate (T10) which you use if you need to file a return. Use SalliMate's Tax Calculator to estimate your monthly deduction.''',
        ),
        _Article(
          title: 'How to Get Your TIN Number',
          tags: ['TIN', 'IRD', 'Registration'],
          body: '''A Tax Identification Number (TIN) is issued by the Inland Revenue Department and is required for most formal financial transactions in Sri Lanka.

You need a TIN to:
• File a tax return (for self-employed or those with multiple income sources)
• Open certain investment accounts
• Apply for business licenses
• Import/export goods commercially

How to register:
1. Visit ird.gov.lk and use the e-Services portal, OR
2. Visit any IRD regional office in person

Documents needed: NIC (or passport), proof of address, and for self-employed — business registration details.

Registration is free and typically processed within 1–3 working days online.''',
        ),
        _Article(
          title: 'EPF & ETF — Your Benefits Explained',
          tags: ['EPF', 'ETF', 'Retirement'],
          body: '''The Employees' Provident Fund (EPF) and Employees' Trust Fund (ETF) are mandatory retirement savings schemes for employees in Sri Lanka.

EPF:
• Employee contributes 8% of gross salary
• Employer contributes 12% of gross salary
• Interest rate: ~9% per annum (set annually by CBSL)
• Can be withdrawn at age 55, on retirement, or permanently leaving employment

ETF:
• Employer contributes 3% of gross salary (employee pays nothing extra)
• Managed by the Employees' Trust Fund Board
• Can be used as collateral for housing loans

How to check your balance: Visit cbsl.gov.lk/epf or the Labour Department portal with your NIC number. Make sure your employer is registering your contributions — non-compliance is common at smaller employers.''',
        ),
      ],
    ),
    _Category(
      title: 'Borrowing',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFFFA726),
      articles: [
        _Article(
          title: 'Flat Rate vs Reducing Balance — Know the Difference',
          tags: ['Loans', 'Interest', 'EMI'],
          body: '''This is one of the most important things to understand before taking any loan in Sri Lanka. The two methods produce very different real costs.

Flat Rate:
Interest is calculated on the full original loan for the entire term, then divided equally across all EMIs.

Reducing Balance (Diminishing Balance):
Interest is calculated on the outstanding principal each month. As you repay, less interest accrues.

Why it matters:
A 15% flat rate loan costs roughly the same as a 27% reducing balance loan. Banks sometimes quote flat rates because the number looks smaller — always ask for the reducing balance equivalent.

SalliMate's Loan Calculator shows both methods so you can compare the true cost of any loan.''',
        ),
        _Article(
          title: 'How Vehicle Leasing Works in Sri Lanka',
          tags: ['Leasing', 'Vehicle', 'LTV'],
          body: '''Leasing is the most common way to finance a vehicle in Sri Lanka. Here's how it differs from a personal loan:

In a lease:
• The bank owns the vehicle until you pay off the full amount
• You pay monthly instalments (EMIs) over a fixed term (typically 1–5 years)
• Once fully paid, ownership transfers to you

Loan-to-Value (LTV) limits set by CBSL:
• Registered vehicles (over 1 year old): up to 70% financed
• Unregistered (brand new): only 40% financed
• Electric vehicles: up to 60%

This means for a brand-new vehicle worth LKR 5,000,000, you must have at least LKR 3,000,000 as a down payment. Always calculate the full cost including interest using SalliMate's Vehicle Leasing Calculator.''',
        ),
        _Article(
          title: 'Debt-to-Income Ratio — Are You Over-Borrowed?',
          tags: ['Debt', 'Financial Health', 'Budgeting'],
          body: '''Your Debt-to-Income (DTI) ratio is the percentage of your monthly gross income that goes towards servicing debt (loan EMIs, leases, credit card minimums).

How to calculate:
DTI = Total Monthly Debt Payments ÷ Gross Monthly Income × 100

What the numbers mean:
• Below 30%: Healthy — you have room for more borrowing if needed
• 30–40%: Moderate — manageable but limit new debt
• Above 40%: High risk — you may struggle to service existing debt
• Above 50%: Danger zone — banks will likely reject new loan applications

Most Sri Lankan banks won't approve loans that push your DTI above 40%. If you're above this, focus on reducing existing debt before taking on new obligations.''',
        ),
      ],
    ),
    _Category(
      title: 'Currency & Remittances',
      icon: Icons.currency_exchange_rounded,
      color: Color(0xFF7E57C2),
      articles: [
        _Article(
          title: 'Understanding Exchange Rates at Sri Lankan Banks',
          tags: ['FX', 'Exchange Rate', 'CBSL'],
          body: '''When you exchange foreign currency at a bank, you will see two rates — buying and selling.

Buying rate: The rate at which the bank buys foreign currency from you (e.g., you sell USD, the bank buys at the lower rate).

Selling rate: The rate at which the bank sells foreign currency to you (e.g., you buy USD, the bank sells at the higher rate).

The gap between them is the bank's spread — this is how they profit from currency exchange. The CBSL publishes a daily reference rate that banks must operate around, but each bank sets its own buying/selling rates within limits.

Practical tip: Shop around. A difference of even LKR 2 per dollar on a USD 1,000 transaction saves you LKR 2,000. SalliMate's Exchange Rate screen compares rates across all major banks in real time.''',
        ),
        _Article(
          title: 'Sending Remittances to Sri Lanka',
          tags: ['Remittance', 'FX', 'Diaspora'],
          body: '''Remittances account for over USD 6 billion per year flowing into Sri Lanka — a critical source of foreign exchange. If you're sending money from overseas or receiving it from family abroad, here's what to know:

How to compare options:
• Don't just look at the exchange rate — also factor in transfer fees
• Total cost = transfer fee + (market rate - bank rate) × amount sent

Common transfer options:
• Bank wire (SWIFT): Reliable but slow (2–3 days) and expensive
• Licensed exchange houses: Often better rates than banks
• Digital services (Wise, WorldRemit): Generally cheapest for major corridors

CBSL requirements:
• Remittances must go through licensed channels
• Amounts above USD 10,000 may require source-of-funds documentation
• No tax on remittances received in Sri Lanka, but declare if investing

Popular corridors: UAE, Saudi Arabia, Qatar, Italy, South Korea, UK, Australia.''',
        ),
        _Article(
          title: 'How CBSL Policy Rates Affect Your Loans & FDs',
          tags: ['CBSL', 'Policy Rate', 'Monetary Policy'],
          body: '''The Central Bank of Sri Lanka (CBSL) sets two key policy rates that influence the entire lending and deposit landscape:

Standing Deposit Facility Rate (SDFR): The rate at which banks deposit excess funds with CBSL — effectively a floor for interest rates.

Standing Lending Facility Rate (SLFR): The rate at which banks borrow from CBSL — effectively a ceiling.

How this affects you:
• When CBSL cuts rates → banks lower FD rates and loan rates
• When CBSL hikes rates → FDs become more attractive, loans get more expensive

After Sri Lanka's 2022 economic crisis, CBSL raised rates sharply to control inflation. Rates have since moderated. Watching CBSL policy announcements (released every 2 months) helps you time FD placements and refinancing decisions.''',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0B0C10),
              pinned: true,
              title: const Text('Knowledge Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i < _categories.length) {
                      return _CategorySection(category: _categories[i]);
                    }
                    return null;
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final _Category category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                category.title,
                style: TextStyle(
                  color: category.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        ...category.articles.map((a) => _ArticleTile(article: a, accentColor: category.color)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final _Article article;
  final Color accentColor;
  const _ArticleTile({required this.article, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            article.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: article.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: TextStyle(color: accentColor, fontSize: 11)),
              )).toList(),
            ),
          ),
          iconColor: accentColor,
          collapsedIconColor: Colors.white38,
          children: [
            const Divider(color: Colors.white12, height: 16),
            Text(
              article.body,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.65),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DATA MODELS ====================

class _Category {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Article> articles;

  const _Category({
    required this.title,
    required this.icon,
    required this.color,
    required this.articles,
  });
}

class _Article {
  final String title;
  final List<String> tags;
  final String body;

  const _Article({
    required this.title,
    required this.tags,
    required this.body,
  });
}
