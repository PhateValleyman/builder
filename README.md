<h1>builder - Interactive Build Tool</h1>

<p><code>builder</code> is an interactive shell script designed to streamline the process of building and installing software packages from source. It guides users through each step, from configuring the build environment to applying patches and compiling the software.</p>

<h2>Features</h2>
<ul>
<li><strong>Interactive Prompts</strong>: Guides users through the build process with clear prompts.</li>
<li><strong>Device Detection</strong>: Automatically detects the environment (e.g., Termux, FFP) and adjusts settings accordingly.</li>
<li><strong>Patch Management</strong>: Applies patches with device-specific adjustments.</li>
<li><strong>Environment Configuration</strong>: Sets appropriate compiler flags and paths based on the detected environment.</li>
<li><strong>Progress Indicators</strong>: Displays colored progress bars during the build process.</li>
<li><strong>Error Handling</strong>: Provides detailed error messages and logs.</li>
<li><strong>Installation Options</strong>: Offers the choice to install the built software to a specified directory.</li>
</ul>

<h2>Installation</h2>
<ol>
<li>Clone the repository:
<pre><code>git clone https://github.com/PhateValleyman/builder.git</code></pre>
</li>
<li>Navigate to the directory:
<pre><code>cd builder</code></pre>
</li>
<li>Make the script executable:
<pre><code>chmod +x builder</code></pre>
</li>
<li>Run the script:
<pre><code>./builder</code></pre>
</li>
</ol>

<h2>Usage</h2>
<pre><code>./builder [--src=SOURCE] [--patch=PATCH] [--configure-options=OPTIONS] [--install-dir=DIR]</code></pre>

<h3>Options:</h3>
<ul>
<li><code>--src=SOURCE</code>: Path to the source directory or archive.</li>
<li><code>--patch=PATCH</code>: Path to a patch file to apply. Can be used multiple times.</li>
<li><code>--configure-options=OPTIONS</code>: Additional options to pass to the <code>./configure</code> script.</li>
<li><code>--install-dir=DIR</code>: Directory to install the built software. Defaults to <code>/data/data/com.termux/files/usr</code> on Termux or <code>/ffp</code> on FFP.</li>
<li><code>--version</code>: Display the version of the builder script.</li>
<li><code>--help</code>: Show this help message.</li>
</ul>

<h2>Example</h2>
<pre><code>./builder --src=~/Downloads/package.tar.gz --patch=~/patches/fix.patch --configure-options="--enable-feature" --install-dir=/usr/local</code></pre>
