import { Hono, type Context } from 'hono';
import { cors } from 'hono/cors';
import { hashPassword, verifyPassword } from './password';
import { signJwt, verifyJwt, type JwtPayload } from './jwt';

export interface Env {
  DB: D1Database;
  FILES: R2Bucket;
  JWT_SECRET: string;
  ENVIRONMENT: string;
}

type Variables = {
  user: JwtPayload;
};

type AppContext = Context<{ Bindings: Env; Variables: Variables }>;

const app = new Hono<{ Bindings: Env; Variables: Variables }>();

app.use('*', cors());

// ---- Autenticação (middleware) ----
async function requireAuth(c: AppContext, next: () => Promise<void>) {
  const auth = c.req.header('Authorization');
  const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return c.json({ error: 'Não autenticado.' }, 401);

  const payload = await verifyJwt(token, c.env.JWT_SECRET);
  if (!payload) return c.json({ error: 'Sessão expirada ou inválida.' }, 401);

  c.set('user', payload);
  await next();
}

async function requireAdmin(c: AppContext, next: () => Promise<void>) {
  const user = c.get('user') as JwtPayload;
  if (user.role !== 'admin') return c.json({ error: 'Acesso restrito ao administrador.' }, 403);
  await next();
}

function newId(): string {
  return crypto.randomUUID();
}

app.get('/health', (c) => c.json({ ok: true, env: c.env.ENVIRONMENT }));

// ---- Arquivos (fotos de anúncios e do chat) ----
// Guardado no R2 e servido pelo próprio Worker — sem precisar de domínio
// público separado para o bucket.

const ALLOWED_UPLOAD_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

app.post('/uploads', requireAuth, async (c) => {
  const contentType = c.req.header('Content-Type') ?? '';
  if (!ALLOWED_UPLOAD_TYPES.includes(contentType)) {
    return c.json({ error: 'Tipo de arquivo não suportado.' }, 400);
  }

  const folder = c.req.query('folder') === 'chat' ? 'chat_images' : 'product_images';
  const extension = contentType.split('/')[1] === 'jpeg' ? 'jpg' : contentType.split('/')[1];
  const key = `${folder}/${c.get('user').sub}/${newId()}.${extension}`;

  const body = await c.req.arrayBuffer();
  if (body.byteLength === 0 || body.byteLength > 8 * 1024 * 1024) {
    return c.json({ error: 'Arquivo vazio ou maior que 8 MB.' }, 400);
  }

  await c.env.FILES.put(key, body, { httpMetadata: { contentType } });

  const origin = new URL(c.req.url).origin;
  return c.json({ url: `${origin}/files/${key}` }, 201);
});

app.get('/files/*', async (c) => {
  const key = c.req.path.replace(/^\/files\//, '');
  const object = await c.env.FILES.get(key);
  if (!object) return c.notFound();

  return new Response(object.body, {
    headers: {
      'Content-Type': object.httpMetadata?.contentType ?? 'application/octet-stream',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
  });
});

// ---- Categorias (público) ----
app.get('/categories', async (c) => {
  const { results } = await c.env.DB.prepare(
    'SELECT id, name, icon, order_index, active FROM categories WHERE active = 1 ORDER BY order_index',
  ).all();
  return c.json(results);
});

// ---- Autenticação ----
app.post('/auth/register', async (c) => {
  const body = await c.req.json<{ name: string; email: string; password: string; phone?: string }>();

  if (!body.name || !body.email || !body.password || body.password.length < 6) {
    return c.json({ error: 'Dados inválidos.' }, 400);
  }

  const existing = await c.env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(body.email).first();
  if (existing) return c.json({ error: 'Este e-mail já está cadastrado.' }, 409);

  const id = newId();
  const passwordHash = await hashPassword(body.password);

  await c.env.DB.prepare(
    'INSERT INTO users (id, name, email, password_hash, phone, role, ad_credits) VALUES (?, ?, ?, ?, ?, ?, ?)',
  )
    .bind(id, body.name, body.email, passwordHash, body.phone ?? null, 'user', 1)
    .run();

  const token = await signJwt(
    { sub: id, email: body.email, role: 'user', exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 },
    c.env.JWT_SECRET,
  );
  return c.json({ token, user: { id, name: body.name, email: body.email, role: 'user', adCredits: 1 } });
});

app.post('/auth/login', async (c) => {
  const body = await c.req.json<{ email: string; password: string }>();

  const user = await c.env.DB.prepare(
    'SELECT id, name, email, password_hash, role, ad_credits FROM users WHERE email = ?',
  )
    .bind(body.email)
    .first<{ id: string; name: string; email: string; password_hash: string; role: string; ad_credits: number }>();

  if (!user || !(await verifyPassword(body.password, user.password_hash))) {
    return c.json({ error: 'E-mail ou senha incorretos.' }, 401);
  }

  const token = await signJwt(
    { sub: user.id, email: user.email, role: user.role, exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 },
    c.env.JWT_SECRET,
  );
  return c.json({
    token,
    user: { id: user.id, name: user.name, email: user.email, role: user.role, adCredits: user.ad_credits },
  });
});

app.get('/me', requireAuth, async (c) => {
  const user = c.get('user');
  const row = await c.env.DB.prepare(
    'SELECT id, name, email, phone, photo_url, role, ad_credits, created_at FROM users WHERE id = ?',
  )
    .bind(user.sub)
    .first();
  if (!row) return c.json({ error: 'Usuário não encontrado.' }, 404);
  return c.json(row);
});

app.patch('/me', requireAuth, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ name?: string; phone?: string; photoUrl?: string }>();

  const fields: string[] = [];
  const values: unknown[] = [];
  if (body.name) {
    fields.push('name = ?');
    values.push(body.name);
  }
  if (body.phone) {
    fields.push('phone = ?');
    values.push(body.phone);
  }
  if (body.photoUrl) {
    fields.push('photo_url = ?');
    values.push(body.photoUrl);
  }
  if (fields.length === 0) return c.json({ error: 'Nada para atualizar.' }, 400);

  values.push(user.sub);
  await c.env.DB.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`)
    .bind(...values)
    .run();

  const row = await c.env.DB.prepare(
    'SELECT id, name, email, phone, photo_url, role, ad_credits, created_at FROM users WHERE id = ?',
  )
    .bind(user.sub)
    .first();
  return c.json(row);
});

// Perfil público de qualquer usuário (ex.: dados do vendedor na tela de
// anúncio) — só os campos que fazem sentido expor, sem e-mail/telefone.
app.get('/users/:id', async (c) => {
  const row = await c.env.DB.prepare(
    'SELECT id, name, photo_url, role, created_at FROM users WHERE id = ?',
  )
    .bind(c.req.param('id'))
    .first();
  if (!row) return c.json({ error: 'Usuário não encontrado.' }, 404);
  return c.json(row);
});

// ---- Anúncios (produtos) ----

const PRODUCT_TTL_DAYS = 40;

function serializeProduct(row: any) {
  return { ...row, image_urls: JSON.parse(row.image_urls ?? '[]') };
}

app.get('/products', async (c) => {
  const category = c.req.query('category');
  const q = c.req.query('q')?.toLowerCase();
  const state = c.req.query('state');
  const city = c.req.query('city');
  const region = c.req.query('region');
  const limit = Math.min(Number(c.req.query('limit') ?? 30), 60);

  const clauses = ["status = 'active'"];
  const params: unknown[] = [];

  if (category) {
    clauses.push('category_id = ?');
    params.push(category);
  }
  if (q) {
    clauses.push('title_lower LIKE ?');
    params.push(`%${q}%`);
  }
  if (state) {
    clauses.push('state = ?');
    params.push(state);
  }
  if (city) {
    clauses.push('city = ?');
    params.push(city);
  }
  if (region) {
    clauses.push('region = ?');
    params.push(region);
  }

  const sql = `SELECT * FROM products WHERE ${clauses.join(' AND ')} ORDER BY created_at DESC LIMIT ?`;
  params.push(limit);

  const { results } = await c.env.DB.prepare(sql).bind(...params).all();
  return c.json(results.map(serializeProduct));
});

app.get('/products/mine', requireAuth, async (c) => {
  const user = c.get('user');
  const { results } = await c.env.DB.prepare(
    'SELECT * FROM products WHERE seller_id = ? ORDER BY created_at DESC',
  )
    .bind(user.sub)
    .all();
  return c.json(results.map(serializeProduct));
});

app.get('/products/:id', async (c) => {
  const row = await c.env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(c.req.param('id')).first();
  if (!row) return c.json({ error: 'Anúncio não encontrado.' }, 404);
  return c.json(serializeProduct(row));
});

app.post('/products', requireAuth, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    title: string;
    description: string;
    price: number;
    imageUrls: string[];
    categoryId: string;
    subcategoryId?: string;
    condition: 'novo' | 'usado';
    quantity: number;
    deliveryOption: 'pickupOnly' | 'deliversInRegion';
    state: string;
    city: string;
    region: string;
  }>();

  if (!body.title || !body.description || !body.price || !body.categoryId || !body.state || !body.city || !body.region) {
    return c.json({ error: 'Preencha todos os campos obrigatórios.' }, 400);
  }

  const dbUser = await c.env.DB.prepare('SELECT ad_credits FROM users WHERE id = ?')
    .bind(user.sub)
    .first<{ ad_credits: number }>();
  if (!dbUser || dbUser.ad_credits < 1) {
    return c.json({ error: 'Você não tem créditos suficientes para publicar um anúncio.' }, 402);
  }

  const id = newId();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + PRODUCT_TTL_DAYS * 24 * 60 * 60 * 1000);

  await c.env.DB.batch([
    c.env.DB.prepare(
      `INSERT INTO products
        (id, seller_id, title, title_lower, description, price, image_urls, category_id, subcategory_id,
         condition, quantity, status, delivery_option, state, city, region, expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?, ?, ?, ?)`,
    ).bind(
      id,
      user.sub,
      body.title,
      body.title.toLowerCase(),
      body.description,
      body.price,
      JSON.stringify(body.imageUrls ?? []),
      body.categoryId,
      body.subcategoryId ?? null,
      body.condition ?? 'usado',
      body.quantity ?? 1,
      body.deliveryOption ?? 'pickupOnly',
      body.state,
      body.city,
      body.region,
      expiresAt.toISOString(),
    ),
    c.env.DB.prepare('UPDATE users SET ad_credits = ad_credits - 1 WHERE id = ?').bind(user.sub),
    c.env.DB.prepare(
      "INSERT INTO credit_transactions (id, user_id, type, amount, description) VALUES (?, ?, 'usage', -1, ?)",
    ).bind(newId(), user.sub, `Publicação do anúncio "${body.title}"`),
  ]);

  const row = await c.env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(id).first();
  return c.json(serializeProduct(row), 201);
});

async function requireProductOwner(c: AppContext, next: () => Promise<void>) {
  const user = c.get('user') as JwtPayload;
  const product = await c.env.DB.prepare('SELECT seller_id FROM products WHERE id = ?')
    .bind(c.req.param('id'))
    .first<{ seller_id: string }>();
  if (!product) return c.json({ error: 'Anúncio não encontrado.' }, 404);
  if (product.seller_id !== user.sub && user.role !== 'admin') {
    return c.json({ error: 'Você não tem permissão sobre este anúncio.' }, 403);
  }
  await next();
}

app.patch('/products/:id/status', requireAuth, requireProductOwner, async (c) => {
  const body = await c.req.json<{ status: 'active' | 'paused' }>();
  if (!['active', 'paused'].includes(body.status)) return c.json({ error: 'Status inválido.' }, 400);

  await c.env.DB.prepare('UPDATE products SET status = ? WHERE id = ?').bind(body.status, c.req.param('id')).run();
  return c.json({ ok: true });
});

app.delete('/products/:id', requireAuth, requireProductOwner, async (c) => {
  await c.env.DB.prepare('DELETE FROM products WHERE id = ?').bind(c.req.param('id')).run();
  return c.json({ ok: true });
});

// ---- Favoritos ----

app.get('/favorites', requireAuth, async (c) => {
  const user = c.get('user');
  const { results } = await c.env.DB.prepare(
    `SELECT p.* FROM favorites f JOIN products p ON p.id = f.product_id
     WHERE f.user_id = ? ORDER BY f.created_at DESC`,
  )
    .bind(user.sub)
    .all();
  return c.json(results.map(serializeProduct));
});

app.post('/favorites/:productId', requireAuth, async (c) => {
  const user = c.get('user');
  await c.env.DB.prepare('INSERT OR IGNORE INTO favorites (id, user_id, product_id) VALUES (?, ?, ?)')
    .bind(newId(), user.sub, c.req.param('productId'))
    .run();
  return c.json({ ok: true });
});

app.delete('/favorites/:productId', requireAuth, async (c) => {
  const user = c.get('user');
  await c.env.DB.prepare('DELETE FROM favorites WHERE user_id = ? AND product_id = ?')
    .bind(user.sub, c.req.param('productId'))
    .run();
  return c.json({ ok: true });
});

// ---- Créditos ----

app.get('/credits', requireAuth, async (c) => {
  const user = c.get('user');
  const balance = await c.env.DB.prepare('SELECT ad_credits FROM users WHERE id = ?')
    .bind(user.sub)
    .first<{ ad_credits: number }>();
  const { results: history } = await c.env.DB.prepare(
    'SELECT * FROM credit_transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
  )
    .bind(user.sub)
    .all();
  return c.json({ balance: balance?.ad_credits ?? 0, history });
});

// A compra de créditos (integração de pagamento) entra aqui quando o
// gateway (Mercado Pago ou outro) for escolhido — endpoint propositalmente
// ainda não criado para não fingir um fluxo de pagamento que não existe.

// ---- Chat ----

app.get('/chats', requireAuth, async (c) => {
  const user = c.get('user');
  const { results } = await c.env.DB.prepare(
    'SELECT * FROM chats WHERE buyer_id = ? OR seller_id = ? ORDER BY last_message_at DESC',
  )
    .bind(user.sub, user.sub)
    .all();
  return c.json(results);
});

app.post('/chats', requireAuth, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ productId: string }>();

  const product = await c.env.DB.prepare('SELECT id, seller_id FROM products WHERE id = ?')
    .bind(body.productId)
    .first<{ id: string; seller_id: string }>();
  if (!product) return c.json({ error: 'Anúncio não encontrado.' }, 404);
  if (product.seller_id === user.sub) return c.json({ error: 'Você não pode conversar com você mesmo.' }, 400);

  const existing = await c.env.DB.prepare(
    'SELECT * FROM chats WHERE product_id = ? AND buyer_id = ? AND seller_id = ?',
  )
    .bind(product.id, user.sub, product.seller_id)
    .first();
  if (existing) return c.json(existing);

  const id = newId();
  await c.env.DB.prepare('INSERT INTO chats (id, product_id, buyer_id, seller_id) VALUES (?, ?, ?, ?)')
    .bind(id, product.id, user.sub, product.seller_id)
    .run();

  const row = await c.env.DB.prepare('SELECT * FROM chats WHERE id = ?').bind(id).first();
  return c.json(row, 201);
});

async function requireChatParticipant(c: AppContext, next: () => Promise<void>) {
  const user = c.get('user') as JwtPayload;
  const chat = await c.env.DB.prepare('SELECT * FROM chats WHERE id = ?')
    .bind(c.req.param('id'))
    .first<{ buyer_id: string; seller_id: string }>();
  if (!chat) return c.json({ error: 'Conversa não encontrada.' }, 404);
  if (chat.buyer_id !== user.sub && chat.seller_id !== user.sub) {
    return c.json({ error: 'Você não participa desta conversa.' }, 403);
  }
  await next();
}

app.get('/chats/:id', requireAuth, requireChatParticipant, async (c) => {
  const row = await c.env.DB.prepare('SELECT * FROM chats WHERE id = ?').bind(c.req.param('id')).first();
  return c.json(row);
});

app.get('/chats/:id/messages', requireAuth, requireChatParticipant, async (c) => {
  const { results } = await c.env.DB.prepare('SELECT * FROM messages WHERE chat_id = ? ORDER BY sent_at ASC')
    .bind(c.req.param('id'))
    .all();
  return c.json(results);
});

app.post('/chats/:id/messages', requireAuth, requireChatParticipant, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ text?: string; imageUrl?: string }>();
  if (!body.text && !body.imageUrl) return c.json({ error: 'Mensagem vazia.' }, 400);

  const id = newId();
  const preview = body.text ?? '📷 Foto';

  await c.env.DB.batch([
    c.env.DB.prepare('INSERT INTO messages (id, chat_id, sender_id, text, image_url) VALUES (?, ?, ?, ?, ?)').bind(
      id,
      c.req.param('id'),
      user.sub,
      body.text ?? '',
      body.imageUrl ?? null,
    ),
    c.env.DB.prepare("UPDATE chats SET last_message = ?, last_message_at = datetime('now') WHERE id = ?").bind(
      preview,
      c.req.param('id'),
    ),
  ]);

  const row = await c.env.DB.prepare('SELECT * FROM messages WHERE id = ?').bind(id).first();
  return c.json(row, 201);
});

// ---- Denúncias ----

app.post('/reports', requireAuth, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ productId?: string; targetUserId?: string; reason: string; details?: string }>();
  if (!body.reason) return c.json({ error: 'Informe o motivo da denúncia.' }, 400);

  await c.env.DB.prepare(
    'INSERT INTO reports (id, reporter_id, product_id, target_user_id, reason, details) VALUES (?, ?, ?, ?, ?, ?)',
  )
    .bind(newId(), user.sub, body.productId ?? null, body.targetUserId ?? null, body.reason, body.details ?? null)
    .run();

  return c.json({ ok: true }, 201);
});

// ---- Administração (painel admin) ----

app.get('/admin/stats', requireAuth, requireAdmin, async (c) => {
  const [users, products, sales, pendingReports] = await Promise.all([
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM users').first<{ n: number }>(),
    c.env.DB.prepare("SELECT COUNT(*) AS n FROM products WHERE status = 'active'").first<{ n: number }>(),
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM sales').first<{ n: number }>(),
    c.env.DB.prepare("SELECT COUNT(*) AS n FROM reports WHERE status = 'pendente'").first<{ n: number }>(),
  ]);
  return c.json({
    totalUsers: users?.n ?? 0,
    activeProducts: products?.n ?? 0,
    totalSales: sales?.n ?? 0,
    pendingReports: pendingReports?.n ?? 0,
  });
});

app.get('/admin/users', requireAuth, requireAdmin, async (c) => {
  const { results } = await c.env.DB.prepare(
    'SELECT id, name, email, phone, role, ad_credits, created_at FROM users ORDER BY created_at DESC LIMIT 200',
  ).all();
  return c.json(results);
});

app.patch('/admin/users/:id/role', requireAuth, requireAdmin, async (c) => {
  const body = await c.req.json<{ role: 'user' | 'admin' }>();
  if (!['user', 'admin'].includes(body.role)) return c.json({ error: 'Papel inválido.' }, 400);
  await c.env.DB.prepare('UPDATE users SET role = ? WHERE id = ?').bind(body.role, c.req.param('id')).run();
  return c.json({ ok: true });
});

app.get('/admin/reports', requireAuth, requireAdmin, async (c) => {
  const { results } = await c.env.DB.prepare('SELECT * FROM reports ORDER BY created_at DESC LIMIT 200').all();
  return c.json(results);
});

app.patch('/admin/reports/:id', requireAuth, requireAdmin, async (c) => {
  const body = await c.req.json<{ status: 'pendente' | 'resolvida' | 'rejeitada' }>();
  if (!['pendente', 'resolvida', 'rejeitada'].includes(body.status)) {
    return c.json({ error: 'Status inválido.' }, 400);
  }
  await c.env.DB.prepare('UPDATE reports SET status = ? WHERE id = ?').bind(body.status, c.req.param('id')).run();
  return c.json({ ok: true });
});

app.delete('/admin/products/:id', requireAuth, requireAdmin, async (c) => {
  await c.env.DB.prepare('DELETE FROM products WHERE id = ?').bind(c.req.param('id')).run();
  return c.json({ ok: true });
});

export default app;
