import GLib from "gi://GLib"
import icons from "lib/icons"
import { dependencies, sh, bash } from "lib/utils"

const now = () => GLib.DateTime.new_now_local().format("%Y-%m-%d_%H-%M-%S")

class Recorder extends Service {
    static {
        Service.register(this, {}, {
            "timer": ["int"],
            "recording": ["boolean"],
        })
    }

    #recordings = Utils.HOME + "/Videos/Screencasting"
    #screenshots = Utils.HOME + "/Pictures/Screenshots"
    #file = ""
    #interval = 0

    recording = false
    timer = 0

    async start() {
        if (!dependencies("slurp", "wl-screenrecord"))
            return

        if (this.recording)
            return

        Utils.ensureDirectory(this.#recordings)
        this.#file = `${this.#recordings}/${now()}.mp4`
        sh(`$HOME/scripts/screenrecord-start.sh`)

        this.recording = true
        this.changed("recording")

        this.timer = 0
        this.#interval = Utils.interval(1000, () => {
            this.changed("timer")
            this.timer++
        })
    }

    async stop() {
        if (!this.recording)
            return

        await sh(`$HOME/scripts/screenrecord-end.sh`)
        this.recording = false
        this.changed("recording")
        GLib.source_remove(this.#interval)

        Utils.notify({
            iconName: icons.fallback.video,
            summary: "Screenrecord",
            body: this.#file,
            actions: {
                "Show in Files": () => sh(`xdg-open ${this.#recordings}`),
                "View": () => sh(`xdg-open ${this.#file}`),
            },
        })
    }

    async screenshot(full = false) {
        if (!dependencies("slurp", "wayshot"))
            return

        const file = `${this.#screenshots}/${now()}.png`
        Utils.ensureDirectory(this.#screenshots)

        if (full) {
            await sh(`wayshot -f ${file}`)
        }
        else {
            const size = await sh("slurp")
            if (!size)
                return

            await sh(`wayshot -f ${file} -s "${size}"`)
        }

        bash(`wl-copy < ${file}`)

        Utils.notify({
            image: file,
            summary: "Screenshot",
            body: file,
            actions: {
                "Show in Files": () => sh(`xdg-open ${this.#screenshots}`),
                "View": () => sh(`xdg-open ${file}`),
                "Edit": () => {
                    if (dependencies("swappy"))
                        sh(`swappy -f ${file}`)
                },
            },
        })
    }
}

const recorder = new Recorder
Object.assign(globalThis, { recorder })
export default recorder
