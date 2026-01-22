import React, { useEffect, useState } from 'react';
import { initClads, renderScalsDocument } from './scals-preview.js';

export interface ScalsPreviewProps {
    /** CLADS document as JSON string or object */
    document: string | object;
    /** Optional path to WASM file */
    wasmPath?: string;
    /** Callback when rendering fails */
    onError?: (error: Error) => void;
}

/**
 * React component for rendering CLADS documents using WebAssembly.
 *
 * @example
 * ```tsx
 * <ScalsPreview
 *   document={cladsJson}
 *   onError={(err) => console.error(err)}
 * />
 * ```
 */
export function ScalsPreview({ document, wasmPath, onError }: ScalsPreviewProps) {
    const [html, setHtml] = useState<string>('');
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<Error | null>(null);

    useEffect(() => {
        let mounted = true;

        async function render() {
            try {
                setIsLoading(true);
                setError(null);

                // Initialize CLADS WASM module
                await initClads(wasmPath);

                if (!mounted) return;

                // Render document
                const renderedHtml = renderScalsDocument(document);

                if (!mounted) return;

                setHtml(renderedHtml);
            } catch (err) {
                const error = err instanceof Error ? err : new Error(String(err));
                if (mounted) {
                    setError(error);
                    onError?.(error);
                }
            } finally {
                if (mounted) {
                    setIsLoading(false);
                }
            }
        }

        render();

        return () => {
            mounted = false;
        };
    }, [document, wasmPath, onError]);

    if (isLoading) {
        return <div>Loading CLADS renderer...</div>;
    }

    if (error) {
        return (
            <div style={{ color: 'red', padding: '1rem', border: '1px solid red' }}>
                <strong>Error rendering CLADS document:</strong>
                <pre>{error.message}</pre>
            </div>
        );
    }

    return <div dangerouslySetInnerHTML={{ __html: html }} />;
}
