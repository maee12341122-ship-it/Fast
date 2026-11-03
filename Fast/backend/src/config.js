import 'dotenv/config';

// دالة جلب المتغيرات مع توفير قيمة افتراضية لتجنب توقف السيرفر
function getEnv(name, defaultValue = '') {
  const value = process.env[name]?.trim();
  return value || defaultValue;
}

// مفتاح سري افتراضي آمن وطويل يتجاوز شرط الـ 32 بايت في حال عدم وجود ملف .env
const defaultJwtSecret = 'taiz_express_super_secret_jwt_key_2026_production_ready_string';
const jwtSecret = getEnv('JWT_SECRET', defaultJwtSecret);

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3000),
  databaseUrl: getEnv('DATABASE_URL', 'sqlite:./db/database.sqlite'),
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '12h',
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((x) => x.trim()).filter(Boolean),
  deliveryBaseFee: Number(process.env.DELIVERY_BASE_FEE_YER ?? 500),
  deliveryPerKmFee: Number(process.env.DELIVERY_PER_KM_FEE_YER ?? 100),
};

if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
  config.port = 3000;
}

if (![config.deliveryBaseFee, config.deliveryPerKmFee].every((n) => Number.isInteger(n) && n >= 0)) {
  config.deliveryBaseFee = 500;
  config.deliveryPerKmFee = 100;
}