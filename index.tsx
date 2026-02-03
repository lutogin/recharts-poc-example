import React from 'react';
import { createRoot } from 'react-dom/client';
import PriceChangeChart from './charts';
import LandPriceChart from './charts2';

const root = document.getElementById('root');
if (root) {
  createRoot(root).render(
    <React.StrictMode>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 48, padding: 24 }}>
        <LandPriceChart />
        <PriceChangeChart />
      </div>
    </React.StrictMode>
  );
}
