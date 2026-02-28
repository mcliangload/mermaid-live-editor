<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { base } from '$app/paths';

  onMount(async () => {
    // Handle old live editor links and redirect to new version
    const hash = window.location.hash.split('/');
    let newURL = 'edit';
    if (hash.length > 2) {
      newURL = `${hash[1]}#${hash[2]}`;
    }
    await goto(`${base}/${newURL}`, {
      replaceState: true
    });

    // 【新增】重定向后确保 Socket.io/Yjs 连接不中断（可选，防止重定向导致连接丢失）
    // 若你的编辑器页面（edit 路径）已处理连接，此段可省略
    setTimeout(() => {
      window.dispatchEvent(new Event('reload-socket-connection'));
    }, 100);
  });
</script>
