<script setup lang="ts">
defineProps<{
  version?: string
  description?: string
}>()
</script>

<template>
  <div class="available-since">
    <span class="label">Available since:</span>

    <template v-if="version">
      <span
        class="version-badge"
        title="action_policy"
        :aria-label="`action_policy version ${version}`"
      >
        <svg class="logo-svg gem-logo" width="16" height="16" viewBox="0 0 32 32" aria-hidden="true" focusable="false">
          <path fill="#CC342D" d="M16 2 L2 10 L2 22 L16 30 L30 22 L30 10 Z"/>
          <path fill="#E44D26" d="M16 2 L2 10 L16 16 L30 10 Z"/>
          <path fill="#B22D28" d="M16 16 L2 10 L2 22 L16 30 Z"/>
          <path fill="#A01E1E" d="M16 16 L30 10 L30 22 L16 30 Z"/>
        </svg>
        <span class="lib-name">action_policy:</span>
        <span class="version-number">{{ version }}</span>
      </span>
    </template>

    <span v-if="description" class="description">{{ description }}</span>

    <div v-if="$slots.default" class="content">
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
.available-since {
  position: relative;
  margin: 12px 0;
  font-size: 15px;
  transition: opacity 0.2s ease;
  display: inline-flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.label {
  font-size: 0.9em;
  font-weight: 700;
  color: var(--vp-c-text-1);
  white-space: nowrap;
}

.version-badge {
  display: inline-flex;
  align-items: center;
  font-size: 0.75em;
  color: var(--vp-c-brand-1);
  font-family: var(--vp-font-family-mono);
  white-space: nowrap;
  background-color: var(--vp-c-brand-soft);
  border-radius: 12px;
  padding: 3px 10px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
  position: relative;
}

.version-badge:hover {
  background-color: var(--vp-c-brand-2);
  color: var(--vp-c-white);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.version-badge:hover .gem-logo path {
  fill: #fff;
}

.version-number {
  margin-left: 4px;
  transition: all 0.3s ease;
}

.lib-name {
  margin-left: 6px;
  font-weight: 500;
}

.logo-svg {
  display: inline-block;
  vertical-align: middle;
  margin-right: 2px;
}

.gem-logo {
  filter: drop-shadow(0 1px 2px rgba(204, 52, 45, 0.3));
}

.description {
  color: var(--vp-c-text-2);
  font-size: 0.9em;
  line-height: 1.4;
  margin: 0;
}

.content {
  position: relative;
  width: 100%;
  margin-top: 8px;
  font-size: 0.9em;
  padding-top: 8px;
  border-top: 1px solid var(--vp-c-divider);
}

@media (max-width: 640px) {
  .available-since {
    gap: 6px;
    flex-direction: column;
    align-items: flex-start;
  }

  .logo-svg {
    margin-right: 4px;
  }
}
</style>
