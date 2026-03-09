<script setup lang="ts">
import { useData } from 'vitepress'

const { isDark } = useData()
</script>

<template>
  <div class="landing">
    <!-- Hero -->
    <section class="hero">
      <div class="hero-inner">
        <div class="hero-heading">
          <img
            class="hero-logo"
            src="/assets/images/logo.svg"
            alt="Action Policy"
          />
          <div class="hero-text">
            <h1 class="hero-title">Authorization framework for Ruby and Rails</h1>
            <p class="hero-tagline">Composable. Extensible. Performant.</p>
          </div>
        </div>
        <div class="hero-actions">
          <a class="btn btn-brand" href="/guide/quick_start">Get Started</a>
          <a
            class="btn btn-alt"
            href="https://github.com/palkan/action_policy"
            target="_blank"
            rel="noopener"
          >
            View on GitHub
          </a>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="features">
      <div class="features-inner">
        <div class="feature-card">
          <h3>Composable Policies</h3>
          <p>Write clean, reusable authorization rules. Compose policies with aliases, pre-checks, and scoping for any complexity level.</p>
        </div>
        <div class="feature-card">
          <h3>Rails Integration</h3>
          <p>Seamless integration with Rails controllers, views, and channels. Works out of the box with zero configuration.</p>
        </div>
        <div class="feature-card">
          <h3>Caching</h3>
          <p>Comprehensive caching system to ensure authorization checks are evaluated once per request.</p>
        </div>
        <div class="feature-card">
          <h3>Testing Tools</h3>
          <p>First-class testing support with RSpec and Minitest matchers. Verify authorization with expressive, readable specs.</p>
        </div>
        <div class="feature-card">
          <h3>Failure Reasons</h3>
          <p>Track exactly why authorization failed. Debug complex policies and provide meaningful feedback to users.</p>
        </div>
        <div class="feature-card">
          <h3>i18n &amp; Debugging</h3>
          <p>Built-in internationalization for error messages and detailed instrumentation for debugging authorization flows.</p>
        </div>
      </div>
    </section>

    <!-- Code Examples -->
    <section class="code-example">
      <div class="code-example-inner">
        <h2>Define policies, authorize actions</h2>
        <div class="code-grid">
          <div class="code-block">
            <div class="code-label">Policy</div>
            <pre><code class="language-ruby"><span class="c"># app/policies/post_policy.rb</span>
<span class="k">class</span> <span class="t">PostPolicy</span> &lt; <span class="t">ApplicationPolicy</span>
  <span class="k">def</span> <span class="m">update?</span>
    user.admin? || (record.author_id == user.id)
  <span class="k">end</span>

  <span class="k">def</span> <span class="m">destroy?</span>
    user.admin?
  <span class="k">end</span>

  <span class="c"># Scope for collections</span>
  relation_scope <span class="k">do</span> |scope|
    <span class="k">if</span> user.admin?
      scope.all
    <span class="k">else</span>
      scope.where(author: user)
    <span class="k">end</span>
  <span class="k">end</span>
<span class="k">end</span></code></pre>
          </div>
          <div class="code-block">
            <div class="code-label">Controller</div>
            <pre><code class="language-ruby"><span class="c"># app/controllers/posts_controller.rb</span>
<span class="k">class</span> <span class="t">PostsController</span> &lt; <span class="t">ApplicationController</span>
  <span class="k">def</span> <span class="m">index</span>
    <span class="c"># Scoped collection</span>
    @posts = authorized_scope(<span class="t">Post</span>.all)
  <span class="k">end</span>

  <span class="k">def</span> <span class="m">update</span>
    @post = <span class="t">Post</span>.find(params[<span class="s">:id</span>])
    <span class="c"># Authorize the action</span>
    authorize! @post
    @post.update!(post_params)
    redirect_to @post
  <span class="k">end</span>
<span class="k">end</span></code></pre>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="landing-footer">
      <div class="footer-inner">
        <p>
          <a href="https://github.com/palkan/action_policy" target="_blank" rel="noopener">GitHub</a>
          <span class="sep">&middot;</span>
          <a href="/guide/">Documentation</a>
          <span class="sep">&middot;</span>
          <a href="https://evilmartians.com" target="_blank" rel="noopener">Evil Martians</a>
        </p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.landing {
  font-family: var(--vp-font-family-base);
  color: var(--vp-c-text-1);
}

/* Hero */
.hero {
  text-align: center;
  padding: 80px 24px 64px;
}

.hero-inner {
  max-width: 720px;
  margin: 0 auto;
}

.hero-heading {
  display: flex;
  align-items: center;
  gap: 32px;
  justify-content: center;
  margin-bottom: 8px;
}

.hero-text {
  text-align: left;
}

.hero-logo {
  width: 140px;
  height: 140px;
  flex-shrink: 0;
}

.hero-title {
  font-size: 2.2rem;
  font-weight: 700;
  line-height: 1.2;
  color: var(--vp-c-brand-2);
  margin: 0 0 8px;
}

.hero-tagline {
  font-size: 1.2rem;
  color: var(--vp-c-text-2);
  margin: 0;
}

.hero-actions {
  display: flex;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 32px;
}

.btn {
  display: inline-block;
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  text-decoration: none;
  transition: background-color 0.2s, color 0.2s, box-shadow 0.2s;
}

.btn-brand {
  background-color: var(--vp-c-brand-3);
  color: var(--vp-c-white);
}

.btn-brand:hover {
  background-color: var(--vp-c-brand-1);
}

.btn-alt {
  background-color: var(--vp-c-default-soft);
  color: var(--vp-c-text-1);
}

.btn-alt:hover {
  background-color: var(--vp-c-default-3);
}

/* Features */
.features {
  padding: 48px 24px 64px;
  background-color: var(--vp-c-bg-soft);
}

.features-inner {
  max-width: 960px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.feature-card {
  background-color: var(--vp-c-bg);
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  padding: 24px;
  transition: box-shadow 0.2s;
}

.feature-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.feature-card h3 {
  font-size: 1.05rem;
  font-weight: 700;
  margin: 0 0 8px;
  color: var(--vp-c-brand-1);
}

.feature-card p {
  font-size: 0.9rem;
  color: var(--vp-c-text-2);
  margin: 0;
  line-height: 1.5;
}

/* Code Examples */
.code-example {
  padding: 64px 24px;
}

.code-example-inner {
  max-width: 960px;
  margin: 0 auto;
  text-align: center;
}

.code-example-inner h2 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0 0 24px;
}

.code-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  text-align: left;
}

.code-block {
  background-color: var(--vp-code-block-bg);
  border-radius: 8px;
  overflow-x: auto;
  font-family: var(--vp-font-family-mono);
  font-size: 0.85rem;
  line-height: 1.7;
}

.code-label {
  padding: 8px 24px;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--vp-c-text-2);
  border-bottom: 1px solid var(--vp-c-divider);
  font-family: var(--vp-font-family-base);
  letter-spacing: 0.02em;
}

.code-block pre {
  margin: 0;
  padding: 16px 24px;
}

.code-block code {
  color: var(--vp-c-text-1);
}

.code-block .k { color: var(--vp-c-brand-1); }
.code-block .t { color: #e0a526; }
.code-block .m { color: var(--vp-c-brand-2); }
.code-block .s { color: #c25; }
.code-block .c { color: var(--vp-c-text-2); font-style: italic; }

.dark .code-block .t { color: #f0c040; }
.dark .code-block .s { color: #f77; }

/* Footer */
.landing-footer {
  padding: 32px 24px;
  border-top: 1px solid var(--vp-c-divider);
  text-align: center;
}

.footer-inner p {
  margin: 0;
  font-size: 0.9rem;
  color: var(--vp-c-text-2);
}

.footer-inner a {
  color: var(--vp-c-brand-1);
  text-decoration: none;
}

.footer-inner a:hover {
  text-decoration: underline;
}

.sep {
  margin: 0 8px;
  color: var(--vp-c-text-3);
}

/* Responsive */
@media (max-width: 768px) {
  .hero {
    padding: 48px 20px 40px;
  }

  .hero-heading {
    flex-direction: column;
    gap: 16px;
  }

  .hero-text {
    text-align: center;
  }

  .hero-logo {
    width: 100px;
    height: 100px;
  }

  .hero-title {
    font-size: 1.6rem;
  }

  .features-inner {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .code-grid {
    grid-template-columns: 1fr;
  }
}

@media (min-width: 769px) and (max-width: 960px) {
  .features-inner {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
