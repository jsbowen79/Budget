import React, { useState } from 'react';
import './App.css';

function App() {
  const [incomeItems, setIncomeItems] = useState([]);
  const [expenseItems, setExpenseItems] = useState([]);

  const [incomeInput, setIncomeInput] = useState({ desc: '', amount: '' });
  const [expenseInput, setExpenseInput] = useState({ desc: '', amount: '', category: 'Other Expenses' });

  const categories = [
    'Housing',
    'Utilities',
    'Groceries',
    'Transportation',
    'Insurance',
    'Healthcare',
    'Debt Payments',
    'Savings',
    'Childcare',
    'Entertainment',
    'Other Expenses'
  ];

  const addIncome = () => {
    const amount = parseFloat(incomeInput.amount);
    if (!incomeInput.desc || isNaN(amount) || amount <= 0) return;

    setIncomeItems([...incomeItems, { ...incomeInput, amount }]);
    setIncomeInput({ desc: '', amount: '' });
  };

  const addExpense = () => {
    const amount = parseFloat(expenseInput.amount);
    if (!expenseInput.desc || isNaN(amount) || amount <= 0) return;

    setExpenseItems([...expenseItems, { ...expenseInput, amount }]);
    setExpenseInput({ desc: '', amount: '', category: 'Other Expenses' });
  };

  const totalIncome = incomeItems.reduce((sum, item) => sum + item.amount, 0);
  const totalExpenses = expenseItems.reduce((sum, item) => sum + item.amount, 0);
  const netBalance = totalIncome - totalExpenses;

  // Group expenses by category
  const groupedExpenses = categories.map(cat => {
    const items = expenseItems.filter(item => item.category === cat);
    const subtotal = items.reduce((sum, item) => sum + item.amount, 0);
    return { category: cat, items, subtotal };
  }).filter(group => group.items.length > 0);

  return (
    <div className="App">
      <h1>React Budget Planner</h1>

      {/* INCOME SECTION */}
      <div className="section">
        <h2>Add Income</h2>
        <input
          type="text"
          placeholder="Income Source"
          value={incomeInput.desc}
          onChange={e => setIncomeInput({ ...incomeInput, desc: e.target.value })}
        />
        <input
          type="number"
          placeholder="Amount"
          value={incomeInput.amount}
          onChange={e => setIncomeInput({ ...incomeInput, amount: e.target.value })}
        />
        <button onClick={addIncome}>Add Income</button>

        <table>
          <thead>
            <tr><th>Source</th><th>Amount</th></tr>
          </thead>
          <tbody>
            {incomeItems.map((item, index) => (
              <tr key={index}><td>{item.desc}</td><td>${item.amount.toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* EXPENSE SECTION */}
      <div className="section">
        <h2>Add Expense</h2>
        <input
          type="text"
          placeholder="Expense Name"
          value={expenseInput.desc}
          onChange={e => setExpenseInput({ ...expenseInput, desc: e.target.value })}
        />
        <input
          type="number"
          placeholder="Amount"
          value={expenseInput.amount}
          onChange={e => setExpenseInput({ ...expenseInput, amount: e.target.value })}
        />
        <label style={{ display: 'block', marginTop: '10px' }}>Category:</label>
        <select
          value={expenseInput.category}
          onChange={e => setExpenseInput({ ...expenseInput, category: e.target.value })}
        >
          {categories.map((cat, i) => (
            <option key={i} value={cat}>{cat}</option>
          ))}
        </select>
        <button onClick={addExpense}>Add Expense</button>

        {/* Grouped Table */}
        {groupedExpenses.map((group, index) => (
          <div key={index}>
            <h3>{group.category}</h3>
            <table>
              <thead>
                <tr><th>Bill</th><th>Amount</th></tr>
              </thead>
              <tbody>
                {group.items.map((item, i) => (
                  <tr key={i}>
                    <td>{item.desc}</td>
                    <td>${item.amount.toFixed(2)}</td>
                  </tr>
                ))}
                <tr>
                  <td><strong>Subtotal</strong></td>
                  <td><strong>${group.subtotal.toFixed(2)}</strong></td>
                </tr>
              </tbody>
            </table>
          </div>
        ))}
      </div>

      {/* SUMMARY */}
      <div className="summary">
        <p>Total Income: ${totalIncome.toFixed(2)}</p>
        <p>Total Expenses: ${totalExpenses.toFixed(2)}</p>
        <p>
          Net Balance: <span className={netBalance >= 0 ? 'positive' : 'negative'}>
            ${netBalance.toFixed(2)}
          </span>
        </p>
      </div>
    </div>
  );
}

export default App;
