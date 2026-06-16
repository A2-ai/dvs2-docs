// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import { remarkBaseUrl } from "./remark-base-url.mjs";
import { starlightKatex } from "starlight-katex";

// https://astro.build/config
export default defineConfig({
  site: process.env.ASTRO_SITE || "http://localhost",
  base: process.env.ASTRO_BASE || "/",
  trailingSlash: "always",
  markdown: {
    remarkPlugins: [remarkBaseUrl],
  },
  integrations: [
    starlight({
      title: "dvs",
      customCss: ["./src/styles/starlightr.css", "./src/styles/custom.css"],
      plugins: [starlightKatex()],
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/A2-ai/dvs2' }],
      sidebar: [
    {
      label: "Articles",
      items: [
        {
          label: "Getting Started",
          collapsed: true,
          items: [
            { label: "Welcome", slug: "articles/readme" }
          ]
        }
      ]
    },
    {
      label: "Reference",
      items: [
        {
          label: "Core Workflow",
          items: [
            { label: "dvs_init", slug: "reference/dvs_init" },
            { label: "dvs_add", slug: "reference/dvs_add" },
            { label: "dvs_status", slug: "reference/dvs_status" },
            { label: "dvs_get", slug: "reference/dvs_get" }
          ]
        },
        {
          label: "Options",
          collapsed: true,
          items: [
            { label: "set_dvs_threads", slug: "reference/set_dvs_threads" },
            { label: "set_dvs_log_level", slug: "reference/set_dvs_log_level" }
          ]
        },
        {
          label: "Byte Sizes",
          collapsed: true,
          items: [
            { label: "format_byte_size", slug: "reference/format_byte_size" },
            { label: "new_dvs_bytes", slug: "reference/new_dvs_bytes" }
          ]
        }
      ]
    }
  ]
    })
  ]
});
