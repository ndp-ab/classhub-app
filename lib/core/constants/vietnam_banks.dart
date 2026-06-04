// Danh sách ngân hàng Việt Nam
// Hard-code 20 ngân hàng phổ biến nhất

class BankItem {
  final String bankName;
  final String shortName;
  final String bankBin;

  const BankItem({
    required this.bankName,
    required this.shortName,
    required this.bankBin,
  });
}

// Danh sách 20 ngân hàng phổ biến VN
const List<BankItem> vietnameseBanks = [
  BankItem(
    bankName: 'Ngân hàng TMCP Quân đội',
    shortName: 'MB Bank',
    bankBin: '970422',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
    shortName: 'Vietcombank',
    bankBin: '970436',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Kỹ Thương Việt Nam',
    shortName: 'Techcombank',
    bankBin: '970407',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Á Châu',
    shortName: 'ACB',
    bankBin: '970416',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Việt Nam Thịnh Vượng',
    shortName: 'VPBank',
    bankBin: '970432',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Công Thương Việt Nam',
    shortName: 'Vietinbank',
    bankBin: '970415',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam',
    shortName: 'BIDV',
    bankBin: '970418',
  ),
  BankItem(
    bankName: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn',
    shortName: 'Agribank',
    bankBin: '970405',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Tiên Phong',
    shortName: 'TPBank',
    bankBin: '970423',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Sài Gòn Thương Tín',
    shortName: 'Sacombank',
    bankBin: '970403',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Sài Gòn - Hà Nội',
    shortName: 'SHB',
    bankBin: '970443',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Xuất Nhập khẩu Việt Nam',
    shortName: 'Eximbank',
    bankBin: '970431',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Hàng Hải',
    shortName: 'MSB',
    bankBin: '970426',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Phương Đông',
    shortName: 'OCB',
    bankBin: '970448',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Sài Gòn Công Thương',
    shortName: 'Saigonbank',
    bankBin: '970400',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Nam Á',
    shortName: 'Nam A Bank',
    bankBin: '970428',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Việt Á',
    shortName: 'VietA Bank',
    bankBin: '970427',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Bưu Điện Liên Việt',
    shortName: 'LienVietPostBank',
    bankBin: '970449',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Quốc Dân',
    shortName: 'NCB',
    bankBin: '970419',
  ),
  BankItem(
    bankName: 'Ngân hàng TMCP Đông Á',
    shortName: 'DongA Bank',
    bankBin: '970406',
  ),
];
